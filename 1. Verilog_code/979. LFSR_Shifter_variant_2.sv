//SystemVerilog
module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire valid_in,
    output wire serial_out,
    output wire valid_out
);
    // 流水线阶段1：LFSR状态寄存器
    reg [WIDTH-1:0] lfsr_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：部分反馈计算阶段
    reg [WIDTH/2-1:0] feedback_partial_stage2_upper;  
    reg [WIDTH/2-1:0] feedback_partial_stage2_lower;
    reg [WIDTH-1:0] lfsr_stage2;
    reg valid_stage2;
    
    // 流水线阶段3：反馈最终计算阶段
    reg feedback_bit_stage3;
    reg [WIDTH-1:0] lfsr_stage3;
    reg valid_stage3;
    
    // 流水线阶段4：输出位寄存器
    reg out_bit_stage4;
    reg valid_stage4;
    
    // 阶段1 - 状态更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_stage1 <= {WIDTH{1'b1}};
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            valid_stage1 <= valid_in;
            if (valid_in) begin
                // 状态仅在阶段3完成后更新
                if (valid_stage3) begin
                    lfsr_stage1 <= {lfsr_stage3[WIDTH-2:0], feedback_bit_stage3};
                end
            end
        end
    end
    
    // 阶段2 - 反馈计算的第一级（将并行计算拆分）
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_partial_stage2_upper <= {(WIDTH/2){1'b0}};
            feedback_partial_stage2_lower <= {(WIDTH/2){1'b0}};
            lfsr_stage2 <= {WIDTH{1'b1}};
            valid_stage2 <= 1'b0;
        end else if (enable) begin
            // 对高位和低位分别计算反馈
            feedback_partial_stage2_upper <= lfsr_stage1[WIDTH-1:WIDTH/2] & TAPS[WIDTH-1:WIDTH/2];
            feedback_partial_stage2_lower <= lfsr_stage1[WIDTH/2-1:0] & TAPS[WIDTH/2-1:0];
            lfsr_stage2 <= lfsr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3 - 反馈计算的第二级（合并结果）
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_bit_stage3 <= 1'b0;
            lfsr_stage3 <= {WIDTH{1'b1}};
            valid_stage3 <= 1'b0;
        end else if (enable) begin
            // 合并高位和低位的异或结果
            feedback_bit_stage3 <= ^feedback_partial_stage2_upper ^ ^feedback_partial_stage2_lower;
            lfsr_stage3 <= lfsr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 阶段4 - 输出生成
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_bit_stage4 <= 1'b1;
            valid_stage4 <= 1'b0;
        end else if (enable) begin
            out_bit_stage4 <= lfsr_stage3[WIDTH-1];
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 输出赋值
    assign serial_out = out_bit_stage4;
    assign valid_out = valid_stage4;
endmodule