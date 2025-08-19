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
    // Pipeline stage registers
    reg stage1_ab, stage1_cd, stage1_ef, stage1_gh;
    reg stage2_abcd, stage2_efgh;
    
    // First pipeline stage reset logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_cd <= 1'b0;
            stage1_ef <= 1'b0;
            stage1_gh <= 1'b0;
        end
    end
    
    // Individual AND operations for first stage pairs
    always @(posedge clk) begin
        if (rst_n) begin
            stage1_ab <= a & b;
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            stage1_cd <= c & d;
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            stage1_ef <= e & f;
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            stage1_gh <= g & h;
        end
    end
    
    // Second pipeline stage reset logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            stage2_abcd <= 1'b0;
            stage2_efgh <= 1'b0;
        end
    end
    
    // Individual AND operations for second stage
    always @(posedge clk) begin
        if (rst_n) begin
            stage2_abcd <= stage1_ab & stage1_cd;
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            stage2_efgh <= stage1_ef & stage1_gh;
        end
    end
    
    // Final output stage reset logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end
    end
    
    // Final output computation
    always @(posedge clk) begin
        if (rst_n) begin
            y <= stage2_abcd & stage2_efgh;
        end
    end
    
endmodule