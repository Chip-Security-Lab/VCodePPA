//SystemVerilog
//IEEE 1364-2005 Verilog标准
module counter_johnson #(
    parameter STAGES = 4  // 计数器级数
)(
    input  wire              clk,        // 系统时钟
    input  wire              rst,        // 复位信号
    output wire [STAGES-1:0] j_reg       // 约翰逊计数器输出
);

    // 内部寄存器声明
    reg [STAGES-1:0] count_r;            // 当前计数值
    reg              feedback_bit_r;     // 反馈位信号寄存器

    // 重构的数据流路径：单阶段时序逻辑，提高清晰度
    always @(posedge clk) begin
        if (rst) begin
            // 复位状态初始化
            count_r      <= {STAGES{1'b0}};
            feedback_bit_r <= 1'b0;
        end 
        else begin
            // 计算反馈位并更新 - 流水线第一级
            feedback_bit_r <= ~count_r[0];
            
            // 移位更新计数器 - 流水线第二级
            count_r <= {feedback_bit_r, count_r[STAGES-1:1]};
        end
    end
    
    // 输出赋值 - 直接连接到寄存器输出
    assign j_reg = count_r;

endmodule