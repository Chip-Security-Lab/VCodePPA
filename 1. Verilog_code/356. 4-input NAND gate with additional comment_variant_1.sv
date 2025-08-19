//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: nand4_2.v
// Description: Optimized 4-input NAND gate with pipelined datapath
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module nand4_2 (
    input  wire clk,     // Clock input
    input  wire rst_n,   // Active-low reset
    input  wire A,       // Data input A
    input  wire B,       // Data input B
    input  wire C,       // Data input C
    input  wire D,       // Data input D
    output wire Y        // NAND output
);

    // Internal signals for pipelined data path
    reg stage1_ab;       // Stage 1: A & B result
    reg stage1_cd;       // Stage 1: C & D result
    reg stage2_result;   // Stage 2: Final NAND result

    // Stage 1: Split the 4-input AND into two 2-input ANDs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_cd <= 1'b0;
        end else begin
            stage1_ab <= A & B;    // First pair AND
            stage1_cd <= C & D;    // Second pair AND
        end
    end

    // Stage 2: Combine the results and negate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b1;  // NAND output is high when reset
        end else begin
            stage2_result <= ~(stage1_ab & stage1_cd);  // NAND operation
        end
    end

    // Output assignment
    assign Y = stage2_result;

endmodule