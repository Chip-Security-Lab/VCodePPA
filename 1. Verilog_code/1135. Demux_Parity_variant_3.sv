//SystemVerilog
module Demux_Parity #(parameter DW=9) (
    input [DW-2:0] data_in,
    input [2:0] addr,
    output reg [7:0][DW-1:0] data_out
);
    wire parity;
    
    // 使用先行借位算法计算奇偶校验
    wire [DW-2:0] p_gen;
    wire [DW-2:0] g_gen;
    wire [DW-1:0] p_chain;
    
    // 生成传播和生成信号
    genvar i;
    generate
        for (i = 0; i < DW-2; i = i + 1) begin : gen_pg
            assign p_gen[i] = data_in[i];
            assign g_gen[i] = data_in[i] & 1'b0; // 由于奇偶校验计算，生成信号为0
        end
    endgenerate
    
    // 计算先行借位链
    assign p_chain[0] = p_gen[0];
    generate
        for (i = 1; i < DW-1; i = i + 1) begin : gen_chain
            assign p_chain[i] = p_gen[i] ^ p_chain[i-1];
        end
    endgenerate
    
    // 最终奇偶校验位
    assign parity = p_chain[DW-2];
    
    // 解复用输出
    always @(*) begin
        data_out = 0;
        data_out[addr] = {parity, data_in};
    end
endmodule