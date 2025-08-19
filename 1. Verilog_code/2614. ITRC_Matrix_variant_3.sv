//SystemVerilog
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
            wire [SOURCES-1:0] masked_input;
            
            // Karatsuba multiplication implementation
            wire [SOURCES/2-1:0] a_high = int_src[SOURCES-1:SOURCES/2];
            wire [SOURCES/2-1:0] a_low = int_src[SOURCES/2-1:0];
            wire [SOURCES/2-1:0] b_high = mask[SOURCES-1:SOURCES/2];
            wire [SOURCES/2-1:0] b_low = mask[SOURCES/2-1:0];
            
            wire [SOURCES-1:0] z0 = a_low * b_low;
            wire [SOURCES-1:0] z2 = a_high * b_high;
            wire [SOURCES-1:0] z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0;
            
            assign masked_input = (z2 << SOURCES) + (z1 << (SOURCES/2)) + z0;
            
            assign int_out[t] = |masked_input;
        end
    endgenerate
endmodule