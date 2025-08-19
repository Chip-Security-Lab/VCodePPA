module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip, // Skip next state
    output reg [3:0] state
);
    always @(posedge clock) begin
        if (reset)
            state <= 4'b0001;
        else if (skip)
            state <= {state[1:0], state[3:2]}; // Skip one state
        else
            state <= {state[2:0], state[3]}; // Normal operation
    end
endmodule