`include "defines.sv"

module l2_clru_tb(); 
    logic clk;
    logic reset;
    logic fill_en;
    logic [1:0] fill_set;
    logic [1:0] fill_way;
    logic lock_en;
    logic lock_value;
    logic access_en;
    logic [1:0] access_set;
    logic access_update_en;
    logic [1:0] access_update_way;

    l2_cache_lru #(.NUM_SETS(1), .NUM_WAYS(4)) DUT(.*);

    localparam DELAY = 10;
    int testways[10]={0,2,1,3,3,2,1,0,2,1};

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
        fill_set = 2'b00;
        lock_en = 1'b0;
        lock_value = 1'b0;
        access_en = 1'b0;
        access_set = 2'b00;
        access_update_en = 1'b0;
        access_update_way = 2'b00;

        @(posedge clk);

        // clear the lock bits
        for(int i = 0; i < 4; i++)
        begin
            lock_en = 1'b1;
            lock_value = 1'b0;
            access_update_way = i;
            @(posedge clk);
            lock_en = 1'b0;
            @(posedge clk);
        end

        // access testing
        for(int i = 0; i < $size(testways); i++)
        begin
            access_en = 1'b1;
            access_update_en = 1'b0;
            @(posedge clk);
            access_en = 1'b0;
            access_update_en = 1'b1;
            access_update_way = testways[i];
            @(posedge clk);
        end

        // fill testing
        access_update_en = 1'b0;
        access_en = 1'b0;
        @(posedge clk);

        for(int i = 0; i < 10; i++)
        begin    
            fill_en = 1'b1;
            @(posedge clk);

            fill_en = 1'b0;
            @(posedge clk);
        end

        for(int j = 0; j < 3; j++)
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

            for(int i = 0; i < 10; i++)
            begin    
                fill_en = 1'b1;
                @(posedge clk);

                fill_en = 1'b0;
                @(posedge clk);
            end
        end


        access_en = 1'b1;
        @(posedge clk);

        access_en = 1'b0;
        // unlock 1, then do more fill testing
        lock_en = 1'b1;
        lock_value = 1'b0;
        access_update_en = 1'b1;
        access_update_way = 2'b10;
        @(posedge clk);
        lock_value = 1'b0;
        lock_en = 1'b0;
        access_update_en = 1'b0;
        @(posedge clk);

        for(int i = 0; i < 10; i++)
        begin    
            fill_en = 1'b1;
            @(posedge clk);

            fill_en = 1'b0;
            @(posedge clk);
        end

        $finish;
    end
endmodule
    
