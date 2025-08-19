module subtractor_8bit (
    input wire clk,              // 时钟信号
    input wire rst_n,            // 异步复位信号
    input wire [7:0] operand_a,  // 被减数
    input wire [7:0] operand_b,  // 减数
    output reg [7:0] result      // 差
);

// 流水线寄存器定义
reg [7:0] operand_a_reg;         // 被减数寄存器
reg [7:0] operand_b_reg;         // 减数寄存器
reg [7:0] operand_b_comp_reg;    // 补码寄存器
reg [7:0] sum_result_reg;        // 加法结果寄存器

// 组合逻辑信号
wire [7:0] operand_b_comp;       // 减数的补码
wire [7:0] sum_result;           // 加法结果

// 流水线级1: 输入寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        operand_a_reg <= 8'b0;
        operand_b_reg <= 8'b0;
    end else begin
        operand_a_reg <= operand_a;
        operand_b_reg <= operand_b;
    end
end

// 流水线级2: 补码计算
assign operand_b_comp = ~operand_b_reg + 8'b1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        operand_b_comp_reg <= 8'b0;
    end else begin
        operand_b_comp_reg <= operand_b_comp;
    end
end

// 流水线级3: 加法运算
assign sum_result = operand_a_reg + operand_b_comp_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_result_reg <= 8'b0;
    end else begin
        sum_result_reg <= sum_result;
    end
end

// 流水线级4: 输出寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result <= 8'b0;
    end else begin
        result <= sum_result_reg;
    end
end

endmodule