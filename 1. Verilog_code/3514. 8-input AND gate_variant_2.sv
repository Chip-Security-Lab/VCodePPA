//SystemVerilog
//IEEE 1364-2005 Verilog standard
module and_gate_8input (
    input wire clk,       // Clock input
    input wire rst_n,     // Active low reset
    input wire a,         // Input A
    input wire b,         // Input B
    input wire c,         // Input C
    input wire d,         // Input D
    input wire e,         // Input E
    input wire f,         // Input F
    input wire g,         // Input G
    input wire h,         // Input H
    output reg y          // Output Y
);
    // Stage 1 registers - first level of AND operations
    reg stage1_a, stage1_b, stage1_c, stage1_d;
    reg stage1_e, stage1_f, stage1_g, stage1_h;
    
    // Stage 2 registers - second level of AND operations
    reg stage2_ab, stage2_cd, stage2_ef, stage2_gh;
    
    // Stage 3 registers - third level of AND operations
    reg stage3_abcd;
    reg stage3_efgh;
    
    // Input registration stage - register all inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
            stage1_c <= 1'b0;
            stage1_d <= 1'b0;
            stage1_e <= 1'b0;
            stage1_f <= 1'b0;
            stage1_g <= 1'b0;
            stage1_h <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
            stage1_c <= c;
            stage1_d <= d;
            stage1_e <= e;
            stage1_f <= f;
            stage1_g <= g;
            stage1_h <= h;
        end
    end
    
    // First computation stage - perform 2-input AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_ab <= 1'b0;
            stage2_cd <= 1'b0;
            stage2_ef <= 1'b0;
            stage2_gh <= 1'b0;
        end else begin
            stage2_ab <= stage1_a & stage1_b;
            stage2_cd <= stage1_c & stage1_d;
            stage2_ef <= stage1_e & stage1_f;
            stage2_gh <= stage1_g & stage1_h;
        end
    end
    
    // Second computation stage - perform 4-input AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_abcd <= 1'b0;
            stage3_efgh <= 1'b0;
        end else begin
            stage3_abcd <= stage2_ab & stage2_cd;
            stage3_efgh <= stage2_ef & stage2_gh;
        end
    end
    
    // Final computation stage - perform 8-input AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage3_abcd & stage3_efgh;
        end
    end
    
endmodule