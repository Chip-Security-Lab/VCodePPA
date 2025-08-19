//SystemVerilog
// Top level module - Optimized NAND gate implementation using pipelined architecture
module nand2_20 (
    input  wire clk,    // Clock signal added for pipelining
    input  wire rst_n,  // Reset signal added for proper initialization
    input  wire A, B,   // Primary inputs
    output reg  Y       // Registered output for improved timing
);
    // Pipeline stage signals with clear naming convention
    reg  stage1_A, stage1_B;       // First pipeline stage inputs
    wire stage1_and_result;        // First stage combinational result
    reg  stage2_and_result;        // Second pipeline stage
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end
    
    // Combinational AND operation
    and_gate_module and_gate_inst (
        .in1(stage1_A),
        .in2(stage1_B),
        .out(stage1_and_result)
    );
    
    // Second pipeline stage - register AND result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_result <= 1'b0;
        end else begin
            stage2_and_result <= stage1_and_result;
        end
    end
    
    // Final stage - NOT operation and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b1;  // Default NAND output is 1 when reset
        end else begin
            Y <= ~stage2_and_result;
        end
    end
    
endmodule

// Optimized AND gate submodule with reduced logic depth
module and_gate_module (
    input  wire in1, in2,
    output wire out
);
    // Perform AND operation with explicit continuous assignment
    // for improved synthesis directives
    assign out = in1 & in2;
endmodule