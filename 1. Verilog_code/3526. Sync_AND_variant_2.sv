//SystemVerilog
module Sync_AND(
    input clk,
    input rst,
    input enable,
    input [7:0] signal_a, signal_b,
    input valid_in,
    output reg valid_out,
    output reg [7:0] reg_out
);
    // 组合逻辑计算阶段
    wire [7:0] and_result;
    wire [1:0] control;
    
    // 组合逻辑部分提前计算
    assign and_result = signal_a & signal_b;
    assign control = {rst, enable};
    
    // 第一级流水线寄存器 - 直接存储计算结果
    reg [7:0] result_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // 第一级流水线 - 直接存储AND计算结果
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: begin  // rst=1, 无论enable值如何
                result_stage1 <= 8'b0;
                valid_stage1 <= 1'b0;
            end
            2'b01: begin  // rst=0, enable=1
                result_stage1 <= and_result;
                valid_stage1 <= valid_in;
            end
            2'b00: begin  // rst=0, enable=0
                // 保持原值
            end
        endcase
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: begin  // rst=1, 无论enable值如何
                result_stage2 <= 8'b0;
                valid_stage2 <= 1'b0;
            end
            2'b01: begin  // rst=0, enable=1
                result_stage2 <= result_stage1;
                valid_stage2 <= valid_stage1;
            end
            2'b00: begin  // rst=0, enable=0
                // 保持原值
            end
        endcase
    end
    
    // 输出级
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: begin  // rst=1, 无论enable值如何
                reg_out <= 8'b0;
                valid_out <= 1'b0;
            end
            2'b01: begin  // rst=0, enable=1
                reg_out <= result_stage2;
                valid_out <= valid_stage2;
            end
            2'b00: begin  // rst=0, enable=0
                // 保持原值
            end
        endcase
    end
endmodule