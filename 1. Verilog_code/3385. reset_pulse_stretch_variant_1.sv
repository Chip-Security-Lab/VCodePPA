//SystemVerilog
module reset_pulse_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input wire clk,
    input wire reset_in,
    output reg reset_out
);
    // 将计数逻辑和输出逻辑分开为两级流水线
    reg [2:0] counter_stage1;
    reg counter_active_stage1;
    reg reset_detected_stage1;
    
    reg [2:0] counter_stage2;
    reg counter_active_stage2;
    reg reset_detected_stage2;
    
    // 使用查找表实现减法运算
    reg [2:0] subtraction_result;
    
    // 查找表 - 用于3位减法运算 (current_value - 1)
    always @(*) begin
        case(counter_stage1)
            3'b001: subtraction_result = 3'b000;
            3'b010: subtraction_result = 3'b001;
            3'b011: subtraction_result = 3'b010;
            3'b100: subtraction_result = 3'b011;
            3'b101: subtraction_result = 3'b100;
            3'b110: subtraction_result = 3'b101;
            3'b111: subtraction_result = 3'b110;
            default: subtraction_result = 3'b000;
        endcase
    end
    
    // 第一级流水线 - 检测复位和计数器逻辑
    always @(posedge clk) begin
        if (reset_in) begin
            counter_stage1 <= STRETCH_COUNT;
            counter_active_stage1 <= 1'b1;
            reset_detected_stage1 <= 1'b1;
        end else if (counter_active_stage1 && counter_stage1 > 0) begin
            counter_stage1 <= subtraction_result; // 使用查找表结果替代减法运算
            counter_active_stage1 <= 1'b1;
            reset_detected_stage1 <= 1'b0;
        end else begin
            counter_active_stage1 <= 1'b0;
            reset_detected_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 传递状态
    always @(posedge clk) begin
        counter_stage2 <= counter_stage1;
        counter_active_stage2 <= counter_active_stage1;
        reset_detected_stage2 <= reset_detected_stage1;
    end
    
    // 第三级流水线 - 生成输出信号
    always @(posedge clk) begin
        if (reset_detected_stage2 || counter_active_stage2) begin
            reset_out <= 1'b1;
        end else begin
            reset_out <= 1'b0;
        end
    end
endmodule