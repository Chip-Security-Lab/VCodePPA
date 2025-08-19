//SystemVerilog
// 8-input AND gate with pipelined structure
module and_gate_8input (
    input wire clk,        // Clock input
    input wire rst_n,      // Active low reset
    input wire a,          // Input A
    input wire b,          // Input B
    input wire c,          // Input C
    input wire d,          // Input D
    input wire e,          // Input E
    input wire f,          // Input F
    input wire g,          // Input G
    input wire h,          // Input H
    output reg y           // Output Y
);

    // Stage 1 registers - first level AND operations
    reg stage1_ab;
    reg stage1_cd;
    reg stage1_ef;
    reg stage1_gh;
    
    // Stage 2 registers - second level AND operations
    reg stage2_abcd;
    reg stage2_efgh;
    
    // First pipeline stage - performing 2-input AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_cd <= 1'b0;
            stage1_ef <= 1'b0;
            stage1_gh <= 1'b0;
        end else begin
            stage1_ab <= a & b;
            stage1_cd <= c & d;
            stage1_ef <= e & f;
            stage1_gh <= g & h;
        end
    end
    
    // Second pipeline stage - performing 4-input AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_abcd <= 1'b0;
            stage2_efgh <= 1'b0;
        end else begin
            stage2_abcd <= stage1_ab & stage1_cd;
            stage2_efgh <= stage1_ef & stage1_gh;
        end
    end
    
    // Final pipeline stage - performing 8-input AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage2_abcd & stage2_efgh;
        end
    end

endmodule