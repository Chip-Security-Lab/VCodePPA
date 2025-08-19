//SystemVerilog
module mode_selectable_comparator (
    input wire clk,                 
    input wire rst_n,               
    input wire [15:0] input_a,
    input wire [15:0] input_b,
    input wire signed_mode,         // 0=unsigned, 1=signed comparison
    output reg is_equal,
    output reg is_greater,
    output reg is_less
);
    // 阶段1: 输入寄存和符号位提取
    reg [15:0] reg_input_a, reg_input_b;
    reg reg_signed_mode;
    reg a_sign, b_sign;  // 单独提取符号位，减少下一阶段逻辑深度
    reg eq_condition;    // 提前计算相等条件，两种模式都相同
    
    // 阶段2: 优化后的计算阶段寄存器
    reg unsigned_gt_stage2, unsigned_lt_stage2;
    reg signed_gt_stage2, signed_lt_stage2;
    reg eq_stage2;  // 合并相等条件，减少逻辑
    
    // 阶段1: 寄存输入数据并提前计算部分条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_input_a <= 16'b0;
            reg_input_b <= 16'b0;
            reg_signed_mode <= 1'b0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            eq_condition <= 1'b0;
        end else begin
            reg_input_a <= input_a;
            reg_input_b <= input_b;
            reg_signed_mode <= signed_mode;
            a_sign <= input_a[15];  // 提前提取符号位
            b_sign <= input_b[15];  // 提前提取符号位
            eq_condition <= (input_a == input_b);  // 提前计算相等条件
        end
    end
    
    // 阶段2: 优化比较逻辑，拆分复杂条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_gt_stage2 <= 1'b0;
            unsigned_lt_stage2 <= 1'b0;
            signed_gt_stage2 <= 1'b0;
            signed_lt_stage2 <= 1'b0;
            eq_stage2 <= 1'b0;
        end else begin
            // 无符号比较 - 直接比较
            unsigned_gt_stage2 <= (reg_input_a > reg_input_b);
            unsigned_lt_stage2 <= (reg_input_a < reg_input_b);
            
            // 有符号比较 - 分解为更简单的逻辑条件
            // 如果符号位不同: 符号位为0的数大于符号位为1的数
            // 如果符号位相同: 正常比较绝对值
            signed_gt_stage2 <= (a_sign ^ b_sign) ? ~a_sign : 
                               (a_sign) ? (reg_input_a < reg_input_b) : 
                                         (reg_input_a > reg_input_b);
                                         
            signed_lt_stage2 <= (a_sign ^ b_sign) ? a_sign : 
                               (a_sign) ? (reg_input_a > reg_input_b) : 
                                         (reg_input_a < reg_input_b);
            
            // 相等条件对有符号和无符号比较是一样的
            eq_stage2 <= eq_condition;
        end
    end
    
    // 阶段3: 基于mode选择比较结果并输出，逻辑更加均衡
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_equal <= 1'b0;
            is_greater <= 1'b0;
            is_less <= 1'b0;
        end else begin
            // 相等条件无需基于模式选择
            is_equal <= eq_stage2;
            
            // 选择大于/小于结果
            is_greater <= reg_signed_mode ? signed_gt_stage2 : unsigned_gt_stage2;
            is_less <= reg_signed_mode ? signed_lt_stage2 : unsigned_lt_stage2;
        end
    end
    
endmodule