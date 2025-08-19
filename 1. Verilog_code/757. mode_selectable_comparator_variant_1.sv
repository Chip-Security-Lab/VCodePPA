//SystemVerilog
module mode_selectable_comparator(
    input wire clk,                 // 添加时钟信号用于流水线寄存器
    input wire rst_n,               // 添加复位信号
    input wire [15:0] input_a,      // 第一个输入操作数
    input wire [15:0] input_b,      // 第二个输入操作数
    input wire signed_mode,         // 模式选择：0=无符号比较，1=有符号比较
    output reg is_equal,            // 等于结果输出
    output reg is_greater,          // 大于结果输出
    output reg is_less              // 小于结果输出
);
    // 第一阶段：输入寄存器
    reg [15:0] reg_input_a, reg_input_b;
    reg reg_signed_mode;
    
    // 第二阶段：比较逻辑计算结果寄存器
    reg unsigned_eq_r, unsigned_gt_r, unsigned_lt_r;
    reg signed_eq_r, signed_gt_r, signed_lt_r;
    
    // 第一阶段：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_input_a <= 16'b0;
            reg_input_b <= 16'b0;
            reg_signed_mode <= 1'b0;
        end else begin
            reg_input_a <= input_a;
            reg_input_b <= input_b;
            reg_signed_mode <= signed_mode;
        end
    end
    
    // 第二阶段：计算比较结果并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 无符号比较结果寄存器复位
            unsigned_eq_r <= 1'b0;
            unsigned_gt_r <= 1'b0;
            unsigned_lt_r <= 1'b0;
            
            // 有符号比较结果寄存器复位
            signed_eq_r <= 1'b0;
            signed_gt_r <= 1'b0;
            signed_lt_r <= 1'b0;
        end else begin
            // 无符号比较计算
            unsigned_eq_r <= (reg_input_a == reg_input_b);
            unsigned_gt_r <= (reg_input_a > reg_input_b);
            unsigned_lt_r <= (reg_input_a < reg_input_b);
            
            // 有符号比较计算
            signed_eq_r <= (reg_input_a == reg_input_b);
            signed_gt_r <= ($signed(reg_input_a) > $signed(reg_input_b));
            signed_lt_r <= ($signed(reg_input_a) < $signed(reg_input_b));
        end
    end
    
    // 第三阶段：根据模式选择最终输出并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_equal <= 1'b0;
            is_greater <= 1'b0;
            is_less <= 1'b0;
        end else begin
            // 根据签名模式选择最终输出
            is_equal <= reg_signed_mode ? signed_eq_r : unsigned_eq_r;
            is_greater <= reg_signed_mode ? signed_gt_r : unsigned_gt_r;
            is_less <= reg_signed_mode ? signed_lt_r : unsigned_lt_r;
        end
    end
endmodule