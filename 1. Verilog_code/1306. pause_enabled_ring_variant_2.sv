//SystemVerilog
///////////////////////////////////////////////////////////
// Module: pause_enabled_ring
// Description: Top-level module for a pause-enabled ring counter
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module pause_enabled_ring (
    input wire clk,       // Clock input
    input wire pause,     // Pause control signal
    input wire rst,       // Reset signal
    output wire [3:0] current_state // Current state of the ring counter
);

    // Internal signals
    wire [3:0] next_state;

    // State calculation module instantiation
    state_calculator state_calc_inst (
        .current_state(current_state),
        .pause(pause),
        .next_state(next_state)
    );

    // State register module instantiation
    state_register state_reg_inst (
        .clk(clk),
        .rst(rst),
        .next_state(next_state),
        .current_state(current_state)
    );

endmodule

///////////////////////////////////////////////////////////
// Module: state_calculator
// Description: Calculates the next state based on current state and pause signal
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module state_calculator (
    input wire [3:0] current_state,
    input wire pause,
    output reg [3:0] next_state
);

    // Calculate next state logic using if-else structure
    // When pause is high, maintain current state
    // Otherwise, rotate the ring counter
    always @(*) begin
        if (pause) begin
            next_state = current_state;
        end else begin
            next_state = {current_state[0], current_state[3:1]};
        end
    end

endmodule

///////////////////////////////////////////////////////////
// Module: state_register
// Description: Registers the state with synchronous reset
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module state_register (
    input wire clk,
    input wire rst,
    input wire [3:0] next_state,
    output reg [3:0] current_state
);

    // State register with synchronous reset
    always @(posedge clk) begin
        if (rst)
            current_state <= 4'b0001; // Reset state
        else
            current_state <= next_state;
    end

endmodule