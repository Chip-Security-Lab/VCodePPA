//SystemVerilog
//===========================================================
// Module: and_gate_3_pipeline
// Standard: IEEE 1364-2005
// Description: Optimized 3-input AND gate with pipelined
//              structure for improved timing and clarity
//===========================================================
module and_gate_3_pipeline (
    input  wire       clk,      // Clock input
    input  wire       rst_n,    // Active-low reset
    input  wire       a,        // Input A
    input  wire       b,        // Input B
    input  wire       c,        // Input C
    output wire       y         // Output Y
);
    // Pipeline stage registers
    reg       stage1_valid;
    reg       stage1_ab_result;
    reg       stage1_c_stored;
    reg       stage2_valid;
    reg       stage2_result;
    
    // Stage 1: Compute partial result (A & B)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_ab_result <= 1'b0;
            stage1_c_stored <= 1'b0;
        end else begin
            stage1_valid <= 1'b1;
            stage1_ab_result <= a & b;  // First partial computation
            stage1_c_stored <= c;       // Store C for next stage
        end
    end
    
    // Stage 2: Complete the operation (AB & C)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_result <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
            stage2_result <= stage1_ab_result & stage1_c_stored;
        end
    end
    
    // Output assignment
    assign y = stage2_result;

endmodule