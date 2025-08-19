//SystemVerilog
module FeedbackShiftRegister #(parameter WIDTH=8) (
    input wire clk,
    input wire en,
    input wire feedback_in,
    output wire serial_out
);
    // Pipeline registers for main shift register
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Intermediate signals for pipeline stages
    wire feedback_bit_stage1;
    reg feedback_bit_stage2;
    wire feedback_result;
    
    // First pipeline stage - compute feedback bit
    assign feedback_bit_stage1 = shift_reg_stage1[WIDTH-1];
    
    // Final output from the last pipeline stage
    assign serial_out = feedback_bit_stage2;
    
    // Feedback computation logic
    assign feedback_result = feedback_in ^ feedback_bit_stage1;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        if (en) begin
            valid_stage1 <= 1'b1;
            shift_reg_stage2 <= shift_reg_stage1;
            feedback_bit_stage2 <= feedback_bit_stage1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        if (en && valid_stage1) begin
            valid_stage2 <= 1'b1;
            shift_reg_stage1 <= {shift_reg_stage2[WIDTH-2:0], feedback_result};
        end else if (en) begin
            // Initial loading or after pipeline flush
            valid_stage2 <= 1'b0;
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], feedback_result};
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Initialize registers to avoid simulation X values
    initial begin
        shift_reg_stage1 = {WIDTH{1'b0}};
        shift_reg_stage2 = {WIDTH{1'b0}};
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        feedback_bit_stage2 = 1'b0;
    end
endmodule