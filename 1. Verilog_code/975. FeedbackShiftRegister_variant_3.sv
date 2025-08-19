//SystemVerilog
module FeedbackShiftRegister #(parameter WIDTH=8) (
    input clk, en,
    input feedback_in,
    output serial_out
);
    // Increased pipeline depth by dividing the shift register into multiple stages
    reg [WIDTH/2-1:0] shift_reg_stage1;
    reg [WIDTH/2-1:0] shift_reg_stage2;
    
    // Pipeline control signals
    reg en_stage2;
    
    // Intermediate signals for pipeline stages
    wire shift_input_stage1;
    wire stage1_output;
    wire pre_output;
    
    // Calculate input for first pipeline stage
    assign shift_input_stage1 = feedback_in ^ shift_reg_stage2[0];
    
    // Connection between pipeline stages
    assign stage1_output = shift_reg_stage1[WIDTH/2-1];
    
    // Pre-output value from second stage
    assign pre_output = shift_reg_stage2[WIDTH/2-2];
    
    // Final output directly from second stage register
    assign serial_out = shift_reg_stage2[WIDTH/2-1];
    
    // First pipeline stage
    always @(posedge clk) begin
        if (en) begin
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH/2-2:0], shift_input_stage1};
            en_stage2 <= en;
        end
    end
    
    // Second pipeline stage
    always @(posedge clk) begin
        if (en_stage2) begin
            shift_reg_stage2 <= {shift_reg_stage2[WIDTH/2-2:0], stage1_output};
        end
    end
endmodule