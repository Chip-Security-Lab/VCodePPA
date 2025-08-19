module ITRC_Matrix #(
    parameter SOURCES = 4,
    parameter TARGETS = 2
)(
    input clk,
    input rst_n,
    input [SOURCES-1:0] int_src,
    input [TARGETS*SOURCES-1:0] routing_map,
    output [TARGETS-1:0] int_out
);
    genvar t;
    generate
        for (t=0; t<TARGETS; t=t+1) begin : gen_target
            wire [SOURCES-1:0] mask = routing_map[t*SOURCES +: SOURCES];
            assign int_out[t] = |(int_src & mask);
        end
    endgenerate
endmodule