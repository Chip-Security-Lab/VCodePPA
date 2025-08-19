//SystemVerilog
// Top level module
module CombinedOR(
    input wire clk,          // 添加时钟信号用于流水线寄存器
    input wire rst_n,        // 添加复位信号
    input wire [1:0] sel,
    input wire [3:0] a, b, c, d,
    output wire [3:0] res
);
    // 第一级流水线 - 输入选择和路径分配
    reg [3:0] path_a_r, path_b_r, path_c_r, path_d_r;
    reg [1:0] sel_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path_a_r <= 4'b0;
            path_b_r <= 4'b0;
            path_c_r <= 4'b0;
            path_d_r <= 4'b0;
            sel_r <= 2'b0;
        end else begin
            path_a_r <= sel[1] ? a : 4'b0;
            path_b_r <= sel[1] ? b : 4'b0;
            path_c_r <= sel[0] ? c : 4'b0;
            path_d_r <= sel[0] ? d : 4'b0;
            sel_r <= sel;
        end
    end
    
    // 第二级流水线 - 子路径合并
    reg [3:0] high_path_or_r, low_path_or_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_path_or_r <= 4'b0;
            low_path_or_r <= 4'b0;
        end else begin
            high_path_or_r <= path_a_r | path_b_r;
            low_path_or_r <= path_c_r | path_d_r;
        end
    end
    
    // 第三级流水线 - 最终结果计算
    reg [3:0] result_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_r <= 4'b0;
        end else begin
            result_r <= high_path_or_r | low_path_or_r;
        end
    end
    
    // 输出赋值
    assign res = result_r;
    
endmodule

// 经过优化的子路径处理模块
module BitwiseORPath(
    input wire clk,          // 添加时钟信号
    input wire rst_n,        // 添加复位信号
    input wire enable,
    input wire [3:0] in1, in2,
    output wire [3:0] result
);
    // 第一级流水线 - 数据与控制信号寄存
    reg [3:0] in1_r, in2_r;
    reg enable_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_r <= 4'b0;
            in2_r <= 4'b0;
            enable_r <= 1'b0;
        end else begin
            in1_r <= in1;
            in2_r <= in2;
            enable_r <= enable;
        end
    end
    
    // 第二级流水线 - 计算OR结果
    reg [3:0] or_result_r;
    reg enable_r2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_r <= 4'b0;
            enable_r2 <= 1'b0;
        end else begin
            or_result_r <= in1_r | in2_r;
            enable_r2 <= enable_r;
        end
    end
    
    // 第三级流水线 - 输出控制
    reg [3:0] result_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_r <= 4'b0;
        end else begin
            result_r <= enable_r2 ? or_result_r : 4'b0;
        end
    end
    
    // 输出赋值
    assign result = result_r;
    
endmodule