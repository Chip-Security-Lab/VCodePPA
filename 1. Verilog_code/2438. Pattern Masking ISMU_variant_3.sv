//SystemVerilog
module pattern_mask_ismu(
    input wire clk, 
    input wire reset,
    input wire valid,              // Renamed from req to valid
    input wire [7:0] interrupt,
    input wire [7:0] mask_pattern,
    input wire [2:0] pattern_sel,
    output wire ready,             // Renamed from ack to ready
    output reg [7:0] masked_interrupt
);
    // Pre-defined constant patterns
    localparam MASK_NONE       = 8'h00;  // No masking
    localparam MASK_ALL        = 8'hFF;  // Mask all
    localparam MASK_LOWER_HALF = 8'h0F;  // Mask lower half
    localparam MASK_UPPER_HALF = 8'hF0;  // Mask upper half
    localparam MASK_ALT_1      = 8'hAA;  // Mask alternating
    localparam MASK_ALT_2      = 8'h55;  // Mask alternating

    reg [7:0] effective_mask;
    reg transfer_done;
    
    // In Valid-Ready protocol, ready indicates the receiver is able to accept data
    assign ready = ~transfer_done;
    
    // Handshake occurs when both valid and ready are high
    wire handshake = valid && ready;
    
    // Processing logic and state management
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            transfer_done <= 1'b0;
            masked_interrupt <= 8'h00;
        end
        else begin
            if (handshake) begin
                // Process data when handshake occurs
                masked_interrupt <= interrupt & ~effective_mask;
                transfer_done <= 1'b1;
            end
            else if (!valid) begin
                // Reset transfer_done when valid is deasserted
                transfer_done <= 1'b0;
            end
        end
    end
    
    // Optimized pattern selection using priority encoding
    always @(*) begin
        // Default value
        effective_mask = MASK_NONE;
        
        // Range-based pattern selection
        if (pattern_sel <= 3'd6) begin
            case (pattern_sel)
                3'd0: effective_mask = MASK_NONE;
                3'd1: effective_mask = MASK_ALL;
                3'd2: effective_mask = MASK_LOWER_HALF;
                3'd3: effective_mask = MASK_UPPER_HALF;
                3'd4: effective_mask = MASK_ALT_1;
                3'd5: effective_mask = MASK_ALT_2;
                3'd6: effective_mask = mask_pattern;
                default: effective_mask = MASK_NONE;
            endcase
        end
    end
endmodule