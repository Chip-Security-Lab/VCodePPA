//SystemVerilog
module pattern_mask_ismu(
    input clk,
    input reset,
    input req,                    // Request signal (transformed from valid)
    input [7:0] interrupt,
    input [7:0] mask_pattern,
    input [2:0] pattern_sel,
    output reg ack,              // Acknowledge signal (transformed from ready)
    output reg [7:0] masked_interrupt
);
    reg [7:0] effective_mask;
    reg data_received;           // Flag to track data processing
    
    // Determine the effective mask based on pattern selection
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
    
    // Req-Ack handshake and data processing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            masked_interrupt <= 8'h00;
            ack <= 1'b0;
            data_received <= 1'b0;
        end
        else begin
            // Handshake protocol handling
            if (req && !data_received) begin
                // Process data when request is active and data hasn't been received
                masked_interrupt <= interrupt & ~effective_mask;
                ack <= 1'b1;             // Assert acknowledge
                data_received <= 1'b1;   // Mark data as received
            end
            else if (!req && data_received) begin
                // Reset handshake when request is deasserted
                ack <= 1'b0;
                data_received <= 1'b0;
            end
        end
    end
endmodule