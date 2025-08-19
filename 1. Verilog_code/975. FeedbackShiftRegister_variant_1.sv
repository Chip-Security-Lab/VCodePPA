//SystemVerilog
module FeedbackShiftRegister #(parameter WIDTH=8) (
    input clk, en,
    input feedback_in,
    output serial_out
);
    // Pipeline registers for each stage
    reg [WIDTH-1:0] stage1_reg;
    reg [WIDTH-1:0] stage2_reg;
    reg [WIDTH-1:0] stage3_reg;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // Split the processing into multiple pipeline stages
    wire feedback_bit = feedback_in ^ stage1_reg[WIDTH-1];
    
    // Pipeline stage control
    always @(posedge clk) begin
        // Stage 1 - Input capture and feedback calculation
        if (en) begin
            stage1_reg <= {stage1_reg[WIDTH-2:0], feedback_bit};
            stage1_valid <= 1'b1;
        end else begin
            stage1_valid <= 1'b0;
        end
        
        // Stage 2 - Intermediate processing
        stage2_reg <= stage1_reg;
        stage2_valid <= stage1_valid;
        
        // Stage 3 - Final processing
        stage3_reg <= stage2_reg;
        stage3_valid <= stage2_valid;
    end
    
    // Output from the final pipeline stage
    assign serial_out = stage3_valid ? stage3_reg[WIDTH-1] : 1'b0;
endmodule