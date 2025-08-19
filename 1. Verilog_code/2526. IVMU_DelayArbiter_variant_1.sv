//SystemVerilog
// SystemVerilog
// Submodule: Handles the delay counter logic
module delay_counter #(
    parameter DELAY = 3
) (
    input wire clk,
    input wire enable, // Enable counting (driven by |irq)
    output wire [DELAY-1:0] counter_value
);

reg [DELAY-1:0] cnt;

always @(posedge clk) begin
    if (enable) begin
        cnt <= (cnt == DELAY-1) ? {DELAY{1'b0}} : cnt + 1;
    end
    // else cnt holds its value
end

assign counter_value = cnt;

endmodule

// Submodule: Calculates the next grant value and update condition
// This module remains combinational, its outputs will be pipelined in the top module
module grant_combinational_logic #(
    parameter DELAY = 3 // Needed to know the size of the counter input
) (
    input wire [3:0] irq,
    input wire [DELAY-1:0] current_counter_value,
    output reg [1:0] next_grant_value, // Changed to reg as assigned in always @(*)
    output wire should_update_grant // condition: current_counter_value == 0 && |irq
);

// Intermediate signals for conditions
wire counter_is_zero_condition = (current_counter_value == {DELAY{1'b0}});
wire any_irq_active_condition = (|irq);

// Calculate the update condition based on intermediate signals
assign should_update_grant = counter_is_zero_condition && any_irq_active_condition;

// Calculate the next grant value based on priority using a clear if-else if structure
always @(*) begin
    if (irq[0]) begin
        // Highest priority: irq[0]
        next_grant_value = 2'd0;
    end else if (irq[1]) begin
        // Next priority: irq[1]
        next_grant_value = 2'd1;
    end else begin
        // Default: covers irq[2] or no irq[0]/irq[1] active
        next_grant_value = 2'd2;
    end
end

endmodule

// Top module: Hierarchical IVMU Delay Arbiter
// Pipelined version: Adds a pipeline stage before the final grant register
module IVMU_DelayArbiter #(
    parameter DELAY = 3
) (
    input wire clk,
    input wire [3:0] irq,
    output wire [1:0] grant
);

// Internal signals
wire irq_active;
wire [DELAY-1:0] current_counter_value;

// Combinational outputs from grant logic submodule
wire [1:0] next_grant_comb;
wire grant_update_cond_comb;

// Pipelined registers for the combinational outputs (Stage 1)
reg [1:0] next_grant_pipe1;
reg grant_update_cond_pipe1;

// Final grant output register (Stage 2 of the pipeline)
reg [1:0] grant_reg;

// Derived signal: any IRQ is active
assign irq_active = |irq;

// Instantiate Delay Counter submodule
delay_counter #(
    .DELAY(DELAY)
) counter_inst (
    .clk(clk),
    .enable(irq_active), // Counter only increments when any IRQ is active
    .counter_value(current_counter_value)
);

// Instantiate Grant Combinational Logic submodule
// Its outputs are now fed into pipeline registers
grant_combinational_logic #(
    .DELAY(DELAY) // Pass DELAY to match counter size for zero check
) grant_logic_inst (
    .irq(irq),
    .current_counter_value(current_counter_value),
    .next_grant_value(next_grant_comb), // Connect to combinational wire
    .should_update_grant(grant_update_cond_comb) // Connect to combinational wire
);

// Pipeline Stage 1: Register the outputs of the combinational logic
// This breaks the critical path from the combinational logic block
always @(posedge clk) begin
    next_grant_pipe1 <= next_grant_comb;
    grant_update_cond_pipe1 <= grant_update_cond_comb;
end

// Pipeline Stage 2: Register the final grant output
// This block now uses the values from the previous cycle (registered in pipe1)
// The grant update is now delayed by one cycle compared to the original logic
always @(posedge clk) begin
    if (grant_update_cond_pipe1) begin
        grant_reg <= next_grant_pipe1;
    end
    // If grant_update_cond_pipe1 is false, grant_reg holds its value.
    // This matches the original behavior where grant is only updated when cnt==0 and |irq is true,
    // but with one cycle of latency.
end

// Assign the registered value to the output
assign grant = grant_reg;

endmodule