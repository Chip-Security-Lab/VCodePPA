//SystemVerilog
// SystemVerilog
module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    input valid_in,
    output reg valid_out,
    output reg [2*WIDTH-1:0] product
);
    // 流水线阶段寄存器
    reg [WIDTH-1:0] multiplier_stage1, multiplier_stage2;
    reg [2*WIDTH-1:0] accum_stage1, accum_stage2;
    reg [WIDTH-1:0] multiplicand_stage1, multiplicand_stage2;
    reg [WIDTH-1:0] bit_count_stage1, bit_count_stage2;
    reg valid_stage1, valid_stage2;
    
    // 计算信号
    wire [2*WIDTH-1:0] shifted_multiplicand_stage1;
    wire add_enable_stage1;
    wire done_stage1;
    
    // 阶段1计算信号
    assign shifted_multiplicand_stage1 = multiplicand_stage1 << bit_count_stage1;
    assign add_enable_stage1 = multiplier_stage1[0];
    assign done_stage1 = (bit_count_stage1 == WIDTH-1);
    
    // 流水线控制
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 重置所有流水线寄存器
            multiplier_stage1 <= 0;
            multiplier_stage2 <= 0;
            multiplicand_stage1 <= 0;
            multiplicand_stage2 <= 0;
            accum_stage1 <= 0;
            accum_stage2 <= 0;
            bit_count_stage1 <= 0;
            bit_count_stage2 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_out <= 0;
            product <= 0;
        end else begin
            // 第一阶段：输入注册及初始化
            if (valid_in) begin
                multiplier_stage1 <= b;
                multiplicand_stage1 <= a;
                accum_stage1 <= 0;
                bit_count_stage1 <= 0;
                valid_stage1 <= 1;
            end else if (valid_stage1 && !done_stage1) begin
                // 继续处理当前乘法操作
                if (add_enable_stage1)
                    accum_stage1 <= accum_stage1 + shifted_multiplicand_stage1;
                multiplier_stage1 <= multiplier_stage1 >> 1;
                bit_count_stage1 <= bit_count_stage1 + 1;
            end else if (valid_stage1 && done_stage1) begin
                // 当前乘法操作完成
                valid_stage1 <= 0;
            end
            
            // 第二阶段：结果处理
            valid_stage2 <= valid_stage1 && done_stage1;
            if (valid_stage1 && done_stage1) begin
                if (add_enable_stage1)
                    accum_stage2 <= accum_stage1 + shifted_multiplicand_stage1;
                else
                    accum_stage2 <= accum_stage1;
            end
            
            // 输出阶段
            valid_out <= valid_stage2;
            if (valid_stage2) begin
                product <= accum_stage2;
            end
        end
    end
endmodule