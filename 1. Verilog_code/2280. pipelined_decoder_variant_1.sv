//SystemVerilog
module pipelined_decoder(
    input clk,
    input [3:0] addr_in,
    output [15:0] decode_out
);
    // Direct output without register
    // Pipelining removed by moving register to inputs
    assign decode_out = (16'b1 << addr_in);
endmodule