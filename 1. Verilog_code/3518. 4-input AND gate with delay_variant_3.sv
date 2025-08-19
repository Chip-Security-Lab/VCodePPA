//SystemVerilog
// Top level module - 4-input AND gate with pipelined implementation
`timescale 1ns / 1ps
`default_nettype none

module and_gate_4_delay (
    input  wire clk,      // Clock input
    input  wire rst_n,    // Active low reset
    input  wire a,        // Input A
    input  wire b,        // Input B
    input  wire c,        // Input C
    input  wire d,        // Input D
    output wire y         // Output Y
);

    // Stage 1: First level computation with registered outputs
    wire stage1_ab;       // Combinational result of A & B
    wire stage1_cd;       // Combinational result of C & D
    reg  stage1_ab_reg;   // Registered result of A & B
    reg  stage1_cd_reg;   // Registered result of C & D
    
    // Stage 2: Final computation with registered output
    wire stage2_y;        // Combinational result of final AND
    reg  stage2_y_reg;    // Registered final output
    
    // Stage 1: First level AND operations
    and_gate_2_delay first_level_ab (
        .a(a),
        .b(b),
        .y(stage1_ab)
    );
    
    and_gate_2_delay first_level_cd (
        .a(c),
        .b(d),
        .y(stage1_cd)
    );
    
    // Stage 2: Final AND operation
    and_gate_2_delay final_level (
        .a(stage1_ab_reg),
        .b(stage1_cd_reg),
        .y(stage2_y)
    );
    
    // Pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            stage1_ab_reg <= 1'b0;
            stage1_cd_reg <= 1'b0;
            stage2_y_reg  <= 1'b0;
        end else begin
            // Update pipeline registers
            stage1_ab_reg <= stage1_ab;
            stage1_cd_reg <= stage1_cd;
            stage2_y_reg  <= stage2_y;
        end
    end
    
    // Assign final output
    assign y = stage2_y_reg;
    
endmodule

// Submodule - 2-input AND gate with optimized delay
module and_gate_2_delay (
    input  wire a,        // Input A
    input  wire b,        // Input B
    output wire y         // Output Y
);
    // Optimized 2-input AND implementation with delay
    assign #0.5 y = a & b;
    
endmodule

`default_nettype wire