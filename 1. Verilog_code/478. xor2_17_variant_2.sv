//SystemVerilog
//===================================================================
// Module: xor2_17
// Description: Optimized 4-input XOR implementation with balanced
//              pipeline structure for improved PPA metrics
//===================================================================
module xor2_17 (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active-low reset
    input  wire A, B, C, D,
    output reg  Y
);

    // Stage 1 signals - First level XOR operations
    reg stage1_xor_ab;
    reg stage1_xor_cd;
    
    // Pipeline stage 1 - Compute first level XORs and register results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_ab <= 1'b0;
            stage1_xor_cd <= 1'b0;
        end
        else begin
            stage1_xor_ab <= A ^ B;  // First input pair XOR
            stage1_xor_cd <= C ^ D;  // Second input pair XOR
        end
    end
    
    // Pipeline stage 2 - Final XOR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end
        else begin
            Y <= stage1_xor_ab ^ stage1_xor_cd;  // Final XOR of intermediate results
        end
    end

endmodule