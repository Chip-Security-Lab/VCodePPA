//SystemVerilog
module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input clk, rst,
    output serial_out
);
    // 流水线寄存器
    reg [WIDTH-1:0] lfsr_stage1;
    reg [WIDTH-1:0] lfsr_stage2;
    reg [WIDTH-1:0] lfsr_stage3;
    
    // 中间结果寄存器
    reg feedback_bit_stage1;
    reg shift_result_stage2;
    reg output_bit_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：计算反馈位
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_stage1 <= {WIDTH{1'b1}};
            feedback_bit_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            lfsr_stage1 <= {WIDTH{1'b1}}; // 仅在复位后的第一个周期设置为全1
            feedback_bit_stage1 <= ^(lfsr_stage3 & TAPS);
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线：执行移位操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_stage2 <= {WIDTH{1'b1}};
            shift_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            lfsr_stage2 <= lfsr_stage1;
            shift_result_stage2 <= feedback_bit_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：更新LFSR状态并输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_stage3 <= {WIDTH{1'b1}};
            output_bit_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // 执行移位，将反馈位放在最低位
            lfsr_stage3 <= {lfsr_stage3[WIDTH-2:0], shift_result_stage2};
            output_bit_stage3 <= lfsr_stage3[WIDTH-1];
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign serial_out = output_bit_stage3;

endmodule