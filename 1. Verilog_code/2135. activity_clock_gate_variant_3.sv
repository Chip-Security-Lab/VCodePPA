//SystemVerilog - IEEE 1364-2005
// Top level module
`timescale 1ns / 1ps
`default_nettype none

module activity_clock_gate (
    input  wire       clk_in,
    input  wire [7:0] data_in,
    input  wire [7:0] prev_data,
    output wire       clk_out
);
    // Internal signals
    wire activity_detected;
    
    // Instantiate activity detector submodule with conditional inverse subtractor
    activity_detector u_activity_detector (
        .current_data    (data_in),
        .previous_data   (prev_data),
        .activity_found  (activity_detected)
    );
    
    // Instantiate clock gating submodule
    clock_gating_cell u_clock_gate (
        .clock_input     (clk_in),
        .enable_signal   (activity_detected),
        .gated_clock     (clk_out)
    );
    
endmodule

// Submodule for detecting changes in data using conditional inverse subtractor
module activity_detector #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] current_data,
    input  wire [DATA_WIDTH-1:0] previous_data,
    output wire                  activity_found
);
    // Internal signals for conditional inverse subtractor
    wire [DATA_WIDTH-1:0] inverted_previous;
    wire [DATA_WIDTH-1:0] subtractor_result;
    wire                  subtraction_mode;
    wire                  carry_in;
    wire                  carry_out;
    
    // Conditional inverse logic for subtraction
    assign subtraction_mode = 1'b1; // We always perform subtraction
    assign carry_in = subtraction_mode;
    assign inverted_previous = subtraction_mode ? ~previous_data : previous_data;
    
    // Adder with carry implementation for subtraction (A - B = A + ~B + 1)
    conditional_inverse_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) u_subtractor (
        .a          (current_data),
        .b          (inverted_previous),
        .cin        (carry_in),
        .result     (subtractor_result),
        .cout       (carry_out)
    );
    
    // Activity is detected when result is non-zero (current_data != previous_data)
    assign activity_found = |subtractor_result;
    
endmodule

// Conditional inverse subtractor module
module conditional_inverse_subtractor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] result,
    output wire             cout
);
    wire [WIDTH:0] carry;
    
    assign carry[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_adder_stage
            assign result[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
    
    assign cout = carry[WIDTH];
    
endmodule

// Submodule for performing clock gating
module clock_gating_cell (
    input  wire clock_input,
    input  wire enable_signal,
    output wire gated_clock
);
    // AND gate based clock gating cell
    assign gated_clock = clock_input & enable_signal;
    
endmodule

`default_nettype wire