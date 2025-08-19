//SystemVerilog
//////////////////////////////////////////////////////////////////////////////////
// Module Name: fsm_reset_sequencer
// Description: Sequential reset signal generator with improved pipeline structure
//              and fan-out buffering for timing optimization
//////////////////////////////////////////////////////////////////////////////////

module fsm_reset_sequencer(
    input  wire       clk,           // System clock
    input  wire       trigger,       // Reset sequence trigger
    output reg  [3:0] reset_signals  // Sequenced reset signals
);

    // State definitions for better readability
    localparam [1:0] STATE_FULL_RESET  = 2'b00,
                     STATE_STAGE1      = 2'b01,
                     STATE_STAGE2      = 2'b10, 
                     STATE_FINAL       = 2'b11;
                     
    // State registers with separate current and next state logic
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // Reset pattern lookup table for cleaner data path
    reg [3:0] reset_pattern;
    
    // Fan-out buffering for next_state signal
    reg [1:0] next_state_buf1, next_state_buf2;
    
    // Fan-out buffering for reset_pattern signal
    reg [3:0] reset_pattern_buf1, reset_pattern_buf2;
    
    // State transition logic - separated from output logic
    always @(*) begin
        case (current_state)
            STATE_FULL_RESET: next_state = STATE_STAGE1;
            STATE_STAGE1:     next_state = STATE_STAGE2;
            STATE_STAGE2:     next_state = STATE_FINAL;
            STATE_FINAL:      next_state = STATE_FINAL;
            default:          next_state = STATE_FULL_RESET;
        endcase
    end
    
    // Reset pattern generation - separated data path
    always @(*) begin
        case (current_state)
            STATE_FULL_RESET: reset_pattern = 4'b1111;
            STATE_STAGE1:     reset_pattern = 4'b0111;
            STATE_STAGE2:     reset_pattern = 4'b0011;
            STATE_FINAL:      reset_pattern = 4'b0000;
            default:          reset_pattern = 4'b1111;
        endcase
    end
    
    // Buffer registers for high fan-out signals
    always @(posedge clk) begin
        // Buffer for next_state
        next_state_buf1 <= next_state;
        next_state_buf2 <= next_state;
        
        // Buffer for reset_pattern
        reset_pattern_buf1 <= reset_pattern;
        reset_pattern_buf2 <= reset_pattern;
    end
    
    // Sequential logic - state update with buffered next_state
    always @(posedge clk) begin
        if (trigger) begin
            current_state <= STATE_FULL_RESET;
        end else begin
            current_state <= next_state_buf1;
        end
    end
    
    // Output register stage using buffered reset_pattern
    always @(posedge clk) begin
        if (trigger) 
            reset_signals <= 4'b1111;
        else
            reset_signals <= reset_pattern_buf2;
    end

endmodule