//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

`include "defines.sv"

//
// Maintains a least recently used list for each cache set. Used to determine
// which cache way to load new cache lines into.
//
// There are two interfaces that update the LRU. The client must assert
// access_en a cycle before updating to fetch the old LRU value.
//
// Fill:
// The cache asserts fill_en and fill_set when it fills a cache line.
// One cycle later, this module sets fill_way to the least recently used way
// (which the cache will replace) and moves that way to the most recently used
// position.
//
// Access:
// During the first cycle of a cache loads, the client asserts access_en and
// access_set. If there was a cache hit, it asserts update_en and update_way
// one cycle later to update the accessed way to the MRU position.
//
// If the client asserts fill_en and access_en simultaneously, fill wins. This
// is important to avoid evicting recently loaded lines when there are many
// fills back to back. It also avoids livelock where two threads evict each
// other's lines back and forth.
//
// Lock:
// Assert lock_en at the same time as access_en or fill_en.
//

module l2_cache_lru
    #(parameter NUM_SETS = 1,
    parameter NUM_WAYS = 4,    // Must be 1, 2, 4, or 8
    parameter SET_INDEX_WIDTH = $clog2(NUM_SETS),
    parameter WAY_INDEX_WIDTH = $clog2(NUM_WAYS))
    (input                                clk,
    input                                 reset,

    // Fill interface. Used to request LRU to replace when filling.
    input                                 fill_en,
    input [SET_INDEX_WIDTH - 1:0]         fill_set,
    output logic [WAY_INDEX_WIDTH - 1:0]  fill_way,

    // Lock interface. Sets the lock bit for way being accessed or filled. 
    input                                 lock_en,
    input                                 lock_value,

    // Access interface. Used to set MRU bits when a way is accessed.
    input                                 access_en,
    input [SET_INDEX_WIDTH - 1:0]         access_set,
    input                                 access_update_en,
    input [WAY_INDEX_WIDTH - 1:0]         access_update_way);

    localparam MRU_BITS = NUM_WAYS;

    logic [MRU_BITS - 1:0] mru_bits;
    logic update_lru_en;
    logic [SET_INDEX_WIDTH - 1:0] update_set;
    logic [MRU_BITS - 1:0] update_mru_bits;
    logic [SET_INDEX_WIDTH - 1:0] read_set;
    logic read_en;
    logic was_fill;
    logic was_lock;
    logic [WAY_INDEX_WIDTH - 1:0] new_mru;
    logic [MRU_BITS - 1:0] new_mru_oh;
    logic [NUM_WAYS - 1:0] lock_bits;           // lock bits mask
    logic [NUM_WAYS - 1:0] update_lock_bits;
    logic [WAY_INDEX_WIDTH - 1:0] lock_way;
    logic lock_unlock;          // store the lock command at the time of access
    logic update_lock_en;
    logic [NUM_WAYS - 1:0] lock_update_oh;
`ifdef SIMULATION
    logic was_access;
`endif

    assign read_en = access_en || fill_en;
    assign read_set = fill_en ? fill_set : access_set;
    assign new_mru = was_fill ? fill_way : access_update_way;
    assign update_lru_en = was_fill || access_update_en;
    assign update_lock_en = was_fill;
    assign lock_way = was_fill ? fill_way : access_update_way;

    sram_1r1w #(
        .DATA_WIDTH(MRU_BITS),
        .SIZE(NUM_SETS),
        .READ_DURING_WRITE("NEW_DATA")
    ) lru_data(
        // Fetch existing flags
        .read_en(read_en),
        .read_addr(read_set),
        .read_data(mru_bits),

        // Update MRU bits (from next stage)
        .write_en(update_lru_en),
        .write_addr(update_set),
        .write_data(update_mru_bits),
        .*);

    sram_1r1w #(
        .DATA_WIDTH(NUM_WAYS),
        .SIZE(NUM_SETS),
        .READ_DURING_WRITE("NEW_DATA")
    ) lock_data(
        .read_en(read_en || lock_en),
        .read_addr(read_set),
        .read_data(lock_bits),

        .write_en(update_lock_en),
        .write_addr(update_set),
        .write_data(update_lock_bits),
        .*);

    idx_to_oh #(.NUM_SIGNALS(MRU_BITS)) idx_to_oh_new_mru(
        .one_hot(new_mru_oh),
        .index(new_mru));

    idx_to_oh #(.NUM_SIGNALS(NUM_WAYS)) idx_to_oh_lock_update(
        .one_hot(lock_update_oh),
        .index(lock_way));

    // if lock_en is asserted:
    // if lock_value is 1, set the locking bit of the desired way.
    // if it's 0, clear that bit instead (unlock).
    //
    always_comb
    begin
        if (was_lock)
            update_lock_bits = lock_unlock ?
                              (lock_bits | lock_update_oh) :
                              (lock_bits & ~lock_update_oh);
        else
            update_lock_bits = '0; 
    end
        
    //
    //  PLRUm algorithm.  Each way has a "MRU" bit which is 0 by default.
    //  That bit is set to 1 when the way is accessed.
    //
    //  If setting a MRU bit will result in all MRU bits being 1, reset
    //  all to 0 except for the new MRU.
    //
    //  If evicting a line, choose the first way with a MRU bit that is 0,
    //  then set that way's MRU flag.
    //

    generate
        case (NUM_WAYS)
            1:
            begin
                assign fill_way = 0;
                assign update_mru_bits = 0;
            end
            
            2:
            begin
                always_comb
                begin
                    casez (mru_bits | lock_bits)
                            2'b?0: fill_way = 0;
                            2'b01: fill_way = 1;
                            default: fill_way = '0;
                    endcase
                    if(&(mru_bits | new_mru_oh | lock_bits))
                        update_mru_bits = new_mru_oh;
                    else
                        update_mru_bits = new_mru_oh | mru_bits;
                end
            end


            4:
            begin
                always_comb
                begin
                    casez (mru_bits | lock_bits)
                            4'b???0: fill_way = 0;
                            4'b??01: fill_way = 1;
                            4'b?011: fill_way = 2; 
                            4'b0111: fill_way = 3;
                            default: fill_way = '0;
                    endcase
                    if(&(mru_bits | new_mru_oh | lock_bits))
                        update_mru_bits = new_mru_oh;
                    else
                        update_mru_bits = new_mru_oh | mru_bits;
                end
            end
            
            8:
            begin
                always_comb
                begin
                    casez (mru_bits | lock_bits)
                            8'b???????0: fill_way = 0;
                            8'b??????01: fill_way = 1;
                            8'b?????011: fill_way = 2; 
                            8'b????0111: fill_way = 3;
                            8'b???01111: fill_way = 4;
                            8'b??011111: fill_way = 5;
                            8'b?0111111: fill_way = 6;
                            8'b01111111: fill_way = 7;
                            default: fill_way = '0;
                    endcase
                    if(&(mru_bits | new_mru_oh | lock_bits))
                        update_mru_bits = new_mru_oh;
                    else
                        update_mru_bits = new_mru_oh | mru_bits;
                end
            end


            default:
            begin
                initial
                begin
                    $display("%m invalid number of ways");
                    $finish;
                end
            end
        endcase
    endgenerate

    always_ff @(posedge clk)
    begin
        update_set <= read_set;
        was_fill <= fill_en;
        was_lock <= lock_en;
        lock_unlock <= lock_value;            
    end

`ifdef SIMULATION
    always_ff @(posedge clk, posedge reset)
    begin
        if (reset)
            was_access <= 0;
        else
        begin
            // Can't update when the last cycle didn't perform an access.
            assert(!(access_update_en && !was_access));
            was_access <= access_en;    // Debug only
        end
    end
`endif
endmodule

// Local Variables:
// verilog-typedef-regexp:"_t$"
// verilog-auto-reset-widths:unbased
// End:
