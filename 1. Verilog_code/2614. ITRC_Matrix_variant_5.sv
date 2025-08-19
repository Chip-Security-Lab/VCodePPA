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
            
            // 使用带符号乘法优化实现
            assign masked_input = int_src & mask;
            
            // 使用查找表优化OR运算
            reg [SOURCES-1:0] or_result;
            always @(*) begin
                case (masked_input)
                    {SOURCES{1'b0}}: or_result = 1'b0;
                    default: or_result = 1'b1;
                endcase
            end
            
            assign int_out[t] = or_result;
        end
    endgenerate
endmodule