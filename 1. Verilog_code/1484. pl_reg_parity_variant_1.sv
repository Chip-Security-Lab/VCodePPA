//SystemVerilog
module pl_reg_parity #(parameter W=8) (
    input clk, load,
    input [W-1:0] data_in,
    output reg [W:0] data_out
);
    // 内部信号定义
    wire parity_bit;
    
    // Brent-Kung树形结构计算奇偶校验
    wire [3:0] p_level1; // 第一级传播信号
    wire [1:0] p_level2; // 第二级传播信号
    
    // 第一级：2位一组计算
    assign p_level1[0] = data_in[0] ^ data_in[1];
    assign p_level1[1] = data_in[2] ^ data_in[3];
    assign p_level1[2] = data_in[4] ^ data_in[5];
    assign p_level1[3] = data_in[6] ^ data_in[7];
    
    // 第二级：4位一组计算
    assign p_level2[0] = p_level1[0] ^ p_level1[1];
    assign p_level2[1] = p_level1[2] ^ p_level1[3];
    
    // 最终奇偶校验位计算
    assign parity_bit = p_level2[0] ^ p_level2[1];
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (load) begin
            data_out <= {parity_bit, data_in};
        end
    end
endmodule