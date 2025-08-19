//SystemVerilog
module Demux_Cascade #(
    parameter DW = 8,
    parameter DEPTH = 2
) (
    input wire clk,
    input wire [DW-1:0] data_in,
    input wire [$clog2(DEPTH+1)-1:0] addr,
    output wire [DEPTH:0][DW-1:0] data_out
);
    // Direct one-hot demux implementation for better timing and area efficiency
    genvar i;
    generate
        for (i = 0; i <= DEPTH; i = i + 1) begin : demux_gen
            assign data_out[i] = (addr == i) ? data_in : {DW{1'b0}};
        end
    endgenerate
endmodule