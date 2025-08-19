//SystemVerilog
module tapped_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] state,
    output reg tap1, tap2 // Changed to reg type as they are now registered
);
    // Next state logic
    wire [3:0] next_state;
    assign next_state = reset ? 4'b0001 : {state[2:0], state[3]};
    
    // Pre-registered tap signals
    wire pre_tap1, pre_tap2;
    assign pre_tap1 = next_state[1]; // Registering directly from next_state[1]
    assign pre_tap2 = next_state[3]; // Registering directly from next_state[3]
    
    always @(posedge clock) begin
        // Main state register
        state <= next_state;
        
        // Directly register the taps from next_state
        // This moves the registers before the buffer logic
        tap1 <= pre_tap1;
        tap2 <= pre_tap2;
    end
endmodule