//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

// Enhanced AND gate with structured data path
module and_gate_generate (
    input  wire clk,       // System clock
    input  wire rst_n,     // Active low reset
    input  wire a_in,      // Input A - first operand
    input  wire b_in,      // Input B - second operand 
    output reg  y_out      // Output Y - result
);

    // Input stage registers
    reg a_stage1, b_stage1;
    
    // Intermediate result
    reg and_result_stage2;
    
    // Input registration stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a_in;
            b_stage1 <= b_in;
        end
    end
    
    // Computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_stage2 <= 1'b0;
        end else begin
            and_result_stage2 <= a_stage1 & b_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= 1'b0;
        end else begin
            y_out <= and_result_stage2;
        end
    end

endmodule

`default_nettype wire