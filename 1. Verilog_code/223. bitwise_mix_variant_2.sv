//SystemVerilog
module bitwise_mix (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_a,
    input wire [7:0] data_b,
    output reg [7:0] xor_out,
    output reg [7:0] nand_out
);

    // 使用单级流水线优化
    reg [7:0] data_a_reg, data_b_reg;
    
    // 组合逻辑优化：使用异或门和与非门的硬件特性
    wire [7:0] xor_result = data_a_reg ^ data_b_reg;
    wire [7:0] nand_result = ~(data_a_reg & data_b_reg);
    
    // 单级流水线实现 - 使用条件运算符替代if-else
    always @(posedge clk or negedge rst_n) begin
        data_a_reg <= !rst_n ? 8'h00 : data_a;
        data_b_reg <= !rst_n ? 8'h00 : data_b;
        xor_out <= !rst_n ? 8'h00 : xor_result;
        nand_out <= !rst_n ? 8'h00 : nand_result;
    end

endmodule