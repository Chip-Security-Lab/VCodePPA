//SystemVerilog
//IEEE 1364-2005 Verilog standard
// Top-level module - Optimized NAND2 implementation
module nand2_15 (
    input  wire clk,     // Clock input (added for pipeline)
    input  wire rst_n,   // Active-low reset (added for pipeline)
    input  wire A, B,    // Data inputs
    output wire Y        // NAND output
);
    // Pipeline stage signals
    reg  stage1_A, stage1_B;    // Input register stage
    wire stage1_and_out;        // AND operation result
    reg  stage2_and_out;        // Registered AND result
    
    // Input registration - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end
    
    // AND operation - between Stage 1 and 2
    assign stage1_and_out = stage1_A & stage1_B;
    
    // AND result registration - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_out <= 1'b0;
        end else begin
            stage2_and_out <= stage1_and_out;
        end
    end
    
    // NOT operation - Final stage
    assign Y = ~stage2_and_out;
    
endmodule