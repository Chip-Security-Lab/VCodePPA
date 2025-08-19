//SystemVerilog
module CombinedOR(
    input wire clk,       
    input wire rst_n,     
    input wire [1:0] sel,
    input wire [3:0] a, b, c, d,
    output reg [3:0] res  
);
    // 第一级流水线：输入数据预处理
    reg [3:0] a_reg, b_reg, c_reg, d_reg;
    reg [1:0] sel_reg;
    
    // 中间信号 - 组合逻辑结果直接传递
    wire [3:0] high_path_wire;
    wire [3:0] low_path_wire;
    wire [3:0] result_wire;
    
    // 输入寄存器级 - 捕获输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            c_reg <= 4'b0;
            d_reg <= 4'b0;
            sel_reg <= 2'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            sel_reg <= sel;
        end
    end
    
    // 组合逻辑计算 - 不再使用中间寄存器
    assign high_path_wire = sel_reg[1] ? (a_reg | b_reg) : 4'b0;
    assign low_path_wire = sel_reg[0] ? (c_reg | d_reg) : 4'b0;
    assign result_wire = high_path_wire | low_path_wire;
    
    // 重定时后的输出寄存器 - 直接在计算结果上寄存
    reg [3:0] high_result_reg, low_result_reg;
    
    // 在组合逻辑前的寄存器化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_result_reg <= 4'b0;
            low_result_reg <= 4'b0;
        end else begin
            high_result_reg <= sel_reg[1] ? (a_reg | b_reg) : 4'b0;
            low_result_reg <= sel_reg[0] ? (c_reg | d_reg) : 4'b0;
        end
    end
    
    // 最终结果计算 - 使用前级寄存过的计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 4'b0;
        end else begin
            res <= high_result_reg | low_result_reg;
        end
    end
endmodule