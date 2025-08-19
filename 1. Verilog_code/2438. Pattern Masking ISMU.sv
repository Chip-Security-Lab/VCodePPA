module pattern_mask_ismu(
    input clk, reset,
    input [7:0] interrupt,
    input [7:0] mask_pattern,
    input [2:0] pattern_sel,
    output reg [7:0] masked_interrupt
);
    reg [7:0] effective_mask;
    
    always @(*) begin
        case (pattern_sel)
            3'd0: effective_mask = 8'h00;         // No masking
            3'd1: effective_mask = 8'hFF;         // Mask all
            3'd2: effective_mask = 8'h0F;         // Mask lower half
            3'd3: effective_mask = 8'hF0;         // Mask upper half
            3'd4: effective_mask = 8'hAA;         // Mask alternating
            3'd5: effective_mask = 8'h55;         // Mask alternating
            3'd6: effective_mask = mask_pattern;  // Custom pattern
            default: effective_mask = 8'h00;
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            masked_interrupt <= 8'h00;
        else
            masked_interrupt <= interrupt & ~effective_mask;
    end
endmodule