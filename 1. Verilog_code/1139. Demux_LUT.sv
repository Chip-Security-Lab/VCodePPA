module Demux_LUT #(parameter DW=8, AW=3, LUT_SIZE=8) (
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output [LUT_SIZE-1:0][DW-1:0] data_out
);
    wire [AW-1:0] actual_addr = remap_table[addr];
    
    // Initialize all outputs to zero
    genvar i;
    generate
        for (i = 0; i < LUT_SIZE; i = i + 1) begin : gen_outputs
            assign data_out[i] = (i == actual_addr && actual_addr < LUT_SIZE) ? data_in : {DW{1'b0}};
        end
    endgenerate
endmodule