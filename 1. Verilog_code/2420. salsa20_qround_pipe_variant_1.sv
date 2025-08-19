//SystemVerilog
module salsa20_qround_pipe (
    input clk, en,
    input [31:0] a, b, c, d,
    output reg [31:0] a_out, d_out
);
    // 中间信号和流水线寄存器声明
    reg [31:0] a_reg, d_reg;  // 输入寄存器
    reg [31:0] sum_a_d;       // a+d的结果
    reg [31:0] rotated_sum_7; // (a+d)<<<7的结果
    reg [31:0] b_reg;         // b的寄存器
    
    reg [31:0] stage1;        // b + rotated_sum_7的结果
    reg [31:0] a_reg2;        // a的流水线寄存器
    
    // 将sum_stage1_a拆分为两步计算，减少关键路径
    reg [31:0] sum_part1;     // 部分和计算
    reg [31:0] sum_stage1_a;  // stage1+a的完整结果
    
    reg [31:0] rotated_sum_9; // (stage1+a)<<<9的结果
    reg [31:0] c_reg;         // c的流水线寄存器
    
    reg [31:0] stage2;        // c ^ rotated_sum_9的结果
    reg [31:0] a_reg3, d_reg3; // 最终输出前的寄存器
    
    // Stage 1: 寄存输入数据并计算a+d
    always @(posedge clk) begin
        if (en) begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            sum_a_d <= a + d;
        end
    end
    
    // Stage 2: 计算循环左移和准备下一阶段
    always @(posedge clk) begin
        if (en) begin
            rotated_sum_7 <= sum_a_d <<< 7;
            a_reg2 <= a_reg;
        end
    end
    
    // Stage 3: 计算b + rotated_sum_7
    always @(posedge clk) begin
        if (en) begin
            stage1 <= b_reg + rotated_sum_7;
            a_reg3 <= a_reg2;
            d_reg3 <= d_reg;
        end
    end
    
    // Stage 4: 开始计算stage1+a，分两步执行
    always @(posedge clk) begin
        if (en) begin
            sum_part1 <= stage1;
            sum_stage1_a <= sum_part1 + a_reg3;
        end
    end
    
    // Stage 5: 计算循环左移
    always @(posedge clk) begin
        if (en) begin
            rotated_sum_9 <= sum_stage1_a <<< 9;
        end
    end
    
    // Stage 6: 计算c ^ rotated_sum_9
    always @(posedge clk) begin
        if (en) begin
            stage2 <= c_reg ^ rotated_sum_9;
        end
    end
    
    // Stage 7: 计算最终输出a_out和d_out
    always @(posedge clk) begin
        if (en) begin
            a_out <= a_reg3 ^ stage2;
            d_out <= d_reg3 + stage2;
        end
    end
endmodule