//SystemVerilog
//============================================================================
// Top-level module: Timer_PhaseAdjust
//============================================================================
`timescale 1ns / 1ps
`default_nettype none

module Timer_PhaseAdjust (
    input wire clk,         // System clock
    input wire rst_n,       // Active low reset
    input wire [3:0] phase, // Phase adjustment value
    output wire out_pulse   // Output pulse signal
);
    // Internal signals for connecting sub-modules
    wire [3:0] counter_value;
    
    // Instantiate counter module
    Counter_Unit counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .counter_value(counter_value)
    );
    
    // Instantiate pulse generator module
    Pulse_Generator pulse_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .counter_value(counter_value),
        .phase(phase),
        .out_pulse(out_pulse)
    );
    
endmodule

//============================================================================
// Sub-module: Counter_Unit
//============================================================================
module Counter_Unit (
    input wire clk,               // System clock
    input wire rst_n,             // Active low reset
    output reg [3:0] counter_value // Current counter value
);
    // Reset logic in separate always block
    always @(negedge rst_n) begin
        if (!rst_n) begin
            counter_value <= 4'h0;
        end
    end
    
    // Counter increment logic in separate always block
    always @(posedge clk) begin
        if (rst_n) begin
            counter_value <= counter_value + 4'h1;
        end
    end
endmodule

//============================================================================
// Sub-module: Pulse_Generator
//============================================================================
module Pulse_Generator (
    input wire clk,               // System clock
    input wire rst_n,             // Active low reset
    input wire [3:0] counter_value, // Current counter value
    input wire [3:0] phase,       // Phase adjustment value
    output reg out_pulse          // Output pulse signal
);
    // Intermediate signal for comparison result
    reg phase_match;
    
    // Phase comparison logic
    always @(*) begin
        phase_match = (counter_value == phase);
    end
    
    // Reset logic in separate always block
    always @(negedge rst_n) begin
        if (!rst_n) begin
            out_pulse <= 1'b0;
        end
    end
    
    // Pulse output logic in separate always block
    always @(posedge clk) begin
        if (rst_n) begin
            out_pulse <= phase_match;
        end
    end
endmodule

`default_nettype wire