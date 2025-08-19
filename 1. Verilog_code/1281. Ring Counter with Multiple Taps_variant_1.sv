//SystemVerilog
`timescale 1ns / 1ps

// Top level module that integrates ring counter components
module tapped_ring_counter #(
    parameter COUNTER_WIDTH = 4,
    parameter INIT_VALUE = 4'b0001,
    parameter TAP1_POS = 1,
    parameter TAP2_POS = 3
)(
    input  wire                  clock,
    input  wire                  reset,
    output wire [COUNTER_WIDTH-1:0] state,
    output wire                  tap1,
    output wire                  tap2
);
    // Internal signals
    wire [COUNTER_WIDTH-1:0] counter_state;
    
    // Ring counter core responsible for state transitions
    ring_counter_core #(
        .WIDTH(COUNTER_WIDTH),
        .INIT_VALUE(INIT_VALUE)
    ) counter_inst (
        .clock(clock),
        .reset(reset),
        .state(counter_state)
    );
    
    // Tap extraction module for accessing specific bits
    tap_extractor #(
        .WIDTH(COUNTER_WIDTH),
        .TAP1_POS(TAP1_POS),
        .TAP2_POS(TAP2_POS)
    ) tap_extractor_inst (
        .state_vector(counter_state),
        .tap1(tap1),
        .tap2(tap2)
    );
    
    // Output assignment
    assign state = counter_state;
    
endmodule

// Core ring counter with parameterized width and initial value
module ring_counter_core #(
    parameter WIDTH = 4,
    parameter INIT_VALUE = 4'b0001
)(
    input  wire             clock,
    input  wire             reset,
    output reg [WIDTH-1:0]  state
);
    // Next state calculation logic
    wire [WIDTH-1:0] next_state;
    
    // State transition logic
    state_transition_logic #(
        .WIDTH(WIDTH)
    ) state_transition_inst (
        .current_state(state),
        .next_state(next_state)
    );
    
    // Sequential logic for state register
    always @(posedge clock) begin
        if (reset)
            state <= INIT_VALUE;
        else
            state <= next_state;
    end
endmodule

// State transition logic module
module state_transition_logic #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] current_state,
    output wire [WIDTH-1:0] next_state
);
    // Ring counter rotation logic
    assign next_state = {current_state[WIDTH-2:0], current_state[WIDTH-1]};
endmodule

// Tap extraction module with configurable tap positions
module tap_extractor #(
    parameter WIDTH = 4,
    parameter TAP1_POS = 1,
    parameter TAP2_POS = 3
)(
    input  wire [WIDTH-1:0] state_vector,
    output wire             tap1,
    output wire             tap2
);
    // Tap signal extraction
    assign tap1 = state_vector[TAP1_POS];
    assign tap2 = state_vector[TAP2_POS];
endmodule