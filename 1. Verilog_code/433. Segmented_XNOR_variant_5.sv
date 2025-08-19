//SystemVerilog
module Segmented_XNOR (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 复位信号，低电平有效
    input  wire [7:0]  high,     // 高位输入
    input  wire [7:0]  low,      // 低位输入
    output reg  [7:0]  res       // 输出结果
);

    // 内部信号声明 - 分割数据路径
    reg [7:0] high_reg, low_reg;         // 输入寄存器
    reg [3:0] high_upper, high_lower;    // 高位输入的上半部分和下半部分
    reg [3:0] low_upper, low_lower;      // 低位输入的上半部分和下半部分
    reg [3:0] xnor_upper, xnor_lower;    // XNOR中间结果
    
    // 第一级流水线 - 高位输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_reg <= 8'b0;
        end else begin
            high_reg <= high;
        end
    end
    
    // 第一级流水线 - 低位输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_reg <= 8'b0;
        end else begin
            low_reg <= low;
        end
    end
    
    // 第二级流水线 - 高位数据分割
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_upper <= 4'b0;
            high_lower <= 4'b0;
        end else begin
            high_upper <= high_reg[7:4];
            high_lower <= high_reg[3:0];
        end
    end
    
    // 第二级流水线 - 低位数据分割
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_upper <= 4'b0;
            low_lower <= 4'b0;
        end else begin
            low_upper <= low_reg[7:4];
            low_lower <= low_reg[3:0];
        end
    end
    
    // 第三级流水线 - 上半部分XNOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_upper <= 4'b0;
        end else begin
            xnor_upper <= ~(high_upper ^ low_lower);  // 高位与低位的低半部分XNOR
        end
    end
    
    // 第三级流水线 - 下半部分XNOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_lower <= 4'b0;
        end else begin
            xnor_lower <= ~(high_lower ^ low_upper);  // 低位与高位的高半部分XNOR
        end
    end
    
    // 第四级流水线 - 结果组合
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'b0;
        end else begin
            res <= {xnor_upper, xnor_lower};  // 组合最终结果
        end
    end

endmodule