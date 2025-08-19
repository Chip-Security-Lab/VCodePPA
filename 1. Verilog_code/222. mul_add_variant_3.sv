//SystemVerilog
module mul_add (
    input wire clk,        // 添加时钟输入以支持流水线
    input wire rst_n,      // 添加复位信号
    input wire [3:0] num1,
    input wire [3:0] num2,
    output reg [7:0] product, // 修改为寄存器输出
    output reg [4:0] sum      // 修改为寄存器输出
);
    // 内部流水线寄存器
    reg [3:0] num1_reg, num2_reg;
    reg [7:0] product_int;
    reg [4:0] sum_int;
    
    // 阶段1：输入寄存化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num1_reg <= 4'b0;
            num2_reg <= 4'b0;
        end else begin
            num1_reg <= num1;
            num2_reg <= num2;
        end
    end
    
    // 阶段2：计算阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_int <= 8'b0;
            sum_int <= 5'b0;
        end else begin
            product_int <= num1_reg * num2_reg;
            sum_int <= num1_reg + num2_reg;
        end
    end
    
    // 阶段3：输出寄存化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'b0;
            sum <= 5'b0;
        end else begin
            product <= product_int;
            sum <= sum_int;
        end
    end
endmodule