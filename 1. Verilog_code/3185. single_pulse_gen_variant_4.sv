//SystemVerilog
module single_pulse_gen #(
    parameter DELAY_CYCLES = 50
)(
    input wire clk,
    input wire trigger,
    output reg pulse
);

// Pipeline stage registers
reg [31:0] counter_stage1, counter_stage2, counter_stage3;
reg state_stage1, state_stage2, state_stage3;
reg trigger_stage1, trigger_stage2;
reg pulse_stage1, pulse_stage2;
reg decrement_flag_stage1, decrement_flag_stage2;
reg pulse_gen_flag_stage1, pulse_gen_flag_stage2;

// Stage 1: Input sampling and state transition logic
always @(posedge clk) begin
    trigger_stage1 <= trigger;
    
    // Optimized state transition logic using range checks
    if (~state_stage3 & trigger_stage1) begin
        state_stage1 <= 1'b1;
        counter_stage1 <= DELAY_CYCLES;
        decrement_flag_stage1 <= 1'b0;
        pulse_gen_flag_stage1 <= 1'b0;
    end else if (state_stage3 & (|counter_stage3)) begin
        state_stage1 <= 1'b1;
        counter_stage1 <= counter_stage3;
        decrement_flag_stage1 <= 1'b1;
        pulse_gen_flag_stage1 <= (counter_stage3 == 32'd2);
    end else begin
        state_stage1 <= state_stage3;
        counter_stage1 <= counter_stage3;
        decrement_flag_stage1 <= 1'b0;
        pulse_gen_flag_stage1 <= 1'b0;
    end
end

// Stage 2: Counter operations
always @(posedge clk) begin
    state_stage2 <= state_stage1;
    trigger_stage2 <= trigger_stage1;
    pulse_gen_flag_stage2 <= pulse_gen_flag_stage1;
    
    // Optimized counter decrement using conditional operator
    counter_stage2 <= decrement_flag_stage1 ? (counter_stage1 - 1'b1) : counter_stage1;
    
    pulse_stage1 <= pulse_gen_flag_stage1;
    decrement_flag_stage2 <= decrement_flag_stage1;
end

// Stage 3: Output and state update
always @(posedge clk) begin
    state_stage3 <= state_stage2;
    counter_stage3 <= counter_stage2;
    
    pulse_stage2 <= pulse_stage1;
    pulse <= pulse_stage2;
    
    // Optimized state transition using bitwise operations
    if (state_stage2 & (counter_stage2 == 32'd1)) begin
        state_stage3 <= 1'b0;
    end
end

endmodule