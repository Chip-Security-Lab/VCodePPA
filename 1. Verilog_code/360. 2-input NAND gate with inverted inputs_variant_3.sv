//SystemVerilog
`timescale 1ns / 1ps

module nand2_4 (
    input  wire clk,       // System clock
    input  wire rst_n,     // Active low reset
    input  wire A,         // First input
    input  wire B,         // Second input
    output wire Y          // Output
);
    // Internal signals for pipelined data path
    reg stage1_a_reg, stage1_b_reg;
    reg stage2_nand_result;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_reg <= 1'b0;
            stage1_b_reg <= 1'b0;
        end else begin
            stage1_a_reg <= A;
            stage1_b_reg <= B;
        end
    end
    
    // Stage 2: Compute NAND and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_nand_result <= 1'b1;  // Default NAND output for reset
        end else begin
            stage2_nand_result <= ~(stage1_a_reg & stage1_b_reg);
        end
    end
    
    // Output assignment
    assign Y = stage2_nand_result;
    
endmodule