//SystemVerilog
module fsm_reset_sequencer(
    input wire clk,
    input wire trigger,
    output reg [3:0] reset_signals
);
    // Pipeline stage registers for state machine
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    reg [1:0] state_stage3;
    
    // Pipeline stage registers for trigger signal
    reg trigger_stage1;
    reg trigger_stage2;
    
    // Pipeline stage registers for reset signals
    reg [3:0] reset_signals_stage1;
    reg [3:0] reset_signals_stage2;
    
    // Next state logic signals
    reg [1:0] next_state_stage1;
    reg [1:0] next_state_stage2;
    
    // Stage 1: Register trigger input
    always @(posedge clk) begin
        trigger_stage1 <= trigger;
    end
    
    // Stage 2: Register trigger again for timing improvement
    always @(posedge clk) begin
        trigger_stage2 <= trigger_stage1;
    end
    
    // Stage 2: Compute initial next state based on trigger
    always @(posedge clk) begin
        if (trigger_stage2) begin
            next_state_stage1 <= 2'b00;
        end else begin
            case (state_stage1)
                2'b00: next_state_stage1 <= 2'b01;
                2'b01: next_state_stage1 <= 2'b10;
                2'b10: next_state_stage1 <= 2'b11;
                2'b11: next_state_stage1 <= 2'b11;
                default: next_state_stage1 <= 2'b00;
            endcase
        end
    end
    
    // Stage 3: Register the computed next state
    always @(posedge clk) begin
        next_state_stage2 <= next_state_stage1;
    end
    
    // Stage 4: Update current state
    always @(posedge clk) begin
        state_stage1 <= next_state_stage2;
    end
    
    // Stage 3: Compute reset signals based on next state or trigger
    always @(posedge clk) begin
        if (trigger_stage2) begin
            reset_signals_stage1 <= 4'b1111;
        end else begin
            case (next_state_stage1)
                2'b00: reset_signals_stage1 <= 4'b1111;
                2'b01: reset_signals_stage1 <= 4'b0111;
                2'b10: reset_signals_stage1 <= 4'b0011;
                2'b11: reset_signals_stage1 <= 4'b0001;
                default: reset_signals_stage1 <= 4'b1111;
            endcase
        end
    end
    
    // Stage 4: Pipeline register for reset signals
    always @(posedge clk) begin
        reset_signals_stage2 <= reset_signals_stage1;
    end
    
    // Stage 5: Final output register
    always @(posedge clk) begin
        reset_signals <= reset_signals_stage2;
    end
    
    // Transfer state through pipeline for debugging and feedback
    always @(posedge clk) begin
        state_stage2 <= state_stage1;
        state_stage3 <= state_stage2;
    end
endmodule