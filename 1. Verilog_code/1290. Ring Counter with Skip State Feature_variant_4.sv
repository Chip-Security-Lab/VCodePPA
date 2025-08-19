//SystemVerilog
//IEEE 1364-2005
module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip, // Skip next state
    output reg [3:0] state
);
    // Register the skip signal to reduce input-to-register delay
    reg skip_reg;
    
    // Pre-compute both possible next states
    wire [3:0] next_state_normal = {state[2:0], state[3]};     // Normal rotation
    wire [3:0] next_state_skip = {state[1:0], state[3:2]};     // Skip rotation
    
    // Register the skip signal
    always @(posedge clock) begin
        if (reset)
            skip_reg <= 1'b0;
        else
            skip_reg <= skip;
    end
    
    // Use registered skip signal for state transition
    always @(posedge clock) begin
        if (reset)
            state <= 4'b0001;
        else
            state <= skip_reg ? next_state_skip : next_state_normal;
    end
endmodule