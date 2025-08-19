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
            wire [SOURCES-1:0] masked_src = int_src & mask;
            reg [SOURCES-1:0] masked_src_reg;
            
            always @(posedge clk or negedge rst_n) begin
                masked_src_reg <= !rst_n ? {SOURCES{1'b0}} : masked_src;
            end
            
            assign int_out[t] = |masked_src_reg;
        end
    endgenerate
endmodule