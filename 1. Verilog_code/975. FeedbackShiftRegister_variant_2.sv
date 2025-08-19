//SystemVerilog - IEEE 1364-2005
module FeedbackShiftRegister #(parameter WIDTH=8) (
    input clk, en,
    input feedback_in,
    output serial_out
);
    // 流水线阶段寄存器
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 反馈位计算 - 将计算前移
    wire feedback_bit = feedback_in ^ shift_reg_stage1[WIDTH-1];
    
    // 第一级流水线 - 状态控制
    always @(posedge clk) begin
        if (en) begin
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第一级流水线 - 数据处理
    always @(posedge clk) begin
        if (en) begin
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], feedback_bit};
        end
    end
    
    // 第二级流水线 - 状态控制
    always @(posedge clk) begin
        valid_stage2 <= valid_stage1;
    end
    
    // 第二级流水线 - 数据处理
    always @(posedge clk) begin
        if (valid_stage1) begin
            shift_reg_stage2 <= shift_reg_stage1;
        end
    end
    
    // 输出赋值 - 直接从第二级流水线寄存器读取
    assign serial_out = shift_reg_stage2[WIDTH-1];

endmodule