//SystemVerilog
module pwm_codec #(parameter RES=10) (
    input wire clk, rst,
    input wire [RES-1:0] duty,
    output reg pwm_out
);
    // Pipeline stage registers
    reg [RES-1:0] cnt_stage1;
    reg [RES-1:0] duty_stage1;
    reg [RES-1:0] duty_stage2;
    reg comparison_result_stage2;
    
    // Counter logic - Stage 1
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt_stage1 <= 0;
            duty_stage1 <= 0;
        end
        else begin
            cnt_stage1 <= cnt_stage1 + 1;
            duty_stage1 <= duty; // Register input duty value
        end
    end
    
    // Comparison logic - Stage 2
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            duty_stage2 <= 0;
            comparison_result_stage2 <= 1'b0;
        end
        else begin
            duty_stage2 <= duty_stage1;
            comparison_result_stage2 <= (cnt_stage1 < duty_stage1);
        end
    end
    
    // Output logic - Stage 3
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pwm_out <= 1'b0;
        end
        else begin
            pwm_out <= comparison_result_stage2;
        end
    end
endmodule