// return the index of the first zero

module find_first_zero
    #(parameter OUT_WIDTH = 4, // out uses one extra bit for not-found
    parameter IN_WIDTH = 1<<(OUT_WIDTH-1)) 
    (input      [IN_WIDTH-1:0]  in,
    output     [OUT_WIDTH-1:0] out);

    wire [OUT_WIDTH-1:0]        out_stage[0:IN_WIDTH];
   
    assign out_stage[0] = ~0; // desired default output if no bits set

    
    generate genvar i;
        for(i=IN_WIDTH; i>0; i--)
        begin : stage 
            assign out_stage[IN_WIDTH-i+1] = in[i] ? i : out_stage[IN_WIDTH-i]; 
        end
    endgenerate

    assign out = out_stage[IN_WIDTH];
endmodule
