//SystemVerilog
// 顶层模块
module CombinedOR(
    input wire clk,         // 添加时钟信号用于流水线寄存器
    input wire rst_n,       // 添加复位信号
    input wire [1:0] sel,
    input wire [3:0] a, b, c, d,
    output wire [3:0] res
);
    // 分解选择信号到流水线寄存器
    reg sel_high_reg, sel_low_reg;
    
    // 输入数据寄存器
    reg [3:0] a_reg, b_reg, c_reg, d_reg;
    
    // 中间结果寄存器
    reg [3:0] or_high_reg, or_low_reg;
    reg [3:0] sel_high_result_reg, sel_low_result_reg;
    
    // 最终结果寄存器
    reg [3:0] result_reg;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            c_reg <= 4'b0;
            d_reg <= 4'b0;
            sel_high_reg <= 1'b0;
            sel_low_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            sel_high_reg <= sel[1];
            sel_low_reg <= sel[0];
        end
    end
    
    // 第二级流水线：计算OR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_high_reg <= 4'b0;
            or_low_reg <= 4'b0;
        end else begin
            or_high_reg <= a_reg | b_reg;
            or_low_reg <= c_reg | d_reg;
        end
    end
    
    // 第三级流水线：选择逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_high_result_reg <= 4'b0;
            sel_low_result_reg <= 4'b0;
        end else begin
            sel_high_result_reg <= sel_high_reg ? or_high_reg : 4'b0;
            sel_low_result_reg <= sel_low_reg ? or_low_reg : 4'b0;
        end
    end
    
    // 第四级流水线：最终结果合并
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 4'b0;
        end else begin
            result_reg <= sel_high_result_reg | sel_low_result_reg;
        end
    end
    
    // 输出赋值
    assign res = result_reg;
    
endmodule