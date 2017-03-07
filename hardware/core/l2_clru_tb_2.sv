// test bench for L2 cache LRU with locking bits.

`include "defines.sv"

module l2_clru_tb_2(); 
    localparam WAYS = 8;
    localparam SETS = 1;
    localparam DELAY = 10;

    logic clk;
    logic reset;
    logic fill_en;
    logic [$clog2(SETS)-1:0] fill_set;
    logic [$clog2(WAYS)-1:0] fill_way;
    logic lock_en;
    logic lock_value;
    logic access_en;
    logic [$clog2(SETS)-1:0] access_set;
    logic access_update_en;
    logic [$clog2(WAYS)-1:0] access_update_way;

    l2_cache_lru #(.NUM_SETS(SETS), .NUM_WAYS(WAYS)) DUT(.*);


    initial
    begin
        clk = 1'b0;

        reset = 1'b1;
        repeat(4) #DELAY clk = ~clk;
        reset = 1'b0;

        forever #DELAY  clk = ~clk;
    end

    initial
    begin
        @(negedge reset);

        fill_en = 1'b0;
        fill_set = 0;
        lock_en = 1'b0;
        lock_value = 1'b0;
        access_en = 1'b0;
        access_set = 0;
        access_update_en = 1'b0;
        access_update_way = 0;
        @(posedge clk);

        // clear all 'x' bits for simulation
        for(int s = 0; s < SETS; s++)
        begin
            access_set = s; 
            for(int i = 0; i < WAYS; i++)
            begin
                lock_en = 1'b1;
                lock_value = 1'b0;
                access_en = 1;
                access_update_en = 0;
                access_update_way = i;
                @(posedge clk);
                lock_en = 1'b0;
                access_en = 0;
                access_update_en = 1;
                @(posedge clk);
            end
        end

        // access testing
        for(int i = 0; i < 32; i++)
        begin
            access_en = 1'b1;
            access_update_en = 1'b0;
            access_set = $urandom_range(SETS-1,0);
            @(posedge clk);
            access_en = 1'b0;
            access_update_en = 1'b1;
            access_update_way = $urandom_range(WAYS-1,0);
            @(posedge clk);
        end

        // fill testing
        access_update_en = 1'b0;
        access_en = 1'b0;
        @(posedge clk);

        for(int i = 0; i < 10; i++)
        begin 
            fill_set = $urandom_range(SETS-1,0);   
            fill_en = 1'b1;
            @(posedge clk);

            fill_en = 1'b0;
            @(posedge clk);
        end

        for(int j = 0; j < (WAYS-1); j++)
        begin
            // lock 1 fill, then do more fill testing
            lock_en = 1'b1;
            lock_value = 1'b1;
            fill_en = 1'b1;
            @(posedge clk);
            lock_value = 1'b0;
            lock_en = 1'b0;
            fill_en = 1'b0; 
            @(posedge clk);

            fill_set = $urandom_range(SETS-1,0);
            for(int i = 0; i < WAYS; i++)
            begin    
                fill_en = 1'b1;
                @(posedge clk);

                fill_en = 1'b0;
                @(posedge clk);
            end
        end

        $finish;
    end
endmodule
    
