//SystemVerilog
//
// Pipelined 4-input AND gate with deeper pipeline architecture for higher frequency
//
module and_gate_4_delay (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active-low reset
    input  wire a,      // Input A
    input  wire b,      // Input B
    input  wire c,      // Input C
    input  wire d,      // Input D
    output reg  y       // Output Y
);

    // Pipeline stage registers - increased pipeline depth
    reg stage1_a, stage1_b, stage1_c, stage1_d;
    reg stage2_a, stage2_b, stage2_c, stage2_d;
    reg stage3_ab, stage3_cd;
    reg stage4_ab, stage4_cd;
    reg stage5_abcd;
    reg stage6_abcd;
    
    // Stage 1: Register all inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
            stage1_c <= 1'b0;
            stage1_d <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
            stage1_c <= c;
            stage1_d <= d;
        end
    end
    
    // Stage 2: Forward registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_a <= 1'b0;
            stage2_b <= 1'b0;
            stage2_c <= 1'b0;
            stage2_d <= 1'b0;
        end else begin
            stage2_a <= stage1_a;
            stage2_b <= stage1_b;
            stage2_c <= stage1_c;
            stage2_d <= stage1_d;
        end
    end
    
    // Stage 3: First level AND operations (parallel)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_ab <= 1'b0;
            stage3_cd <= 1'b0;
        end else begin
            stage3_ab <= stage2_a & stage2_b;
            stage3_cd <= stage2_c & stage2_d;
        end
    end
    
    // Stage 4: Register partial results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_ab <= 1'b0;
            stage4_cd <= 1'b0;
        end else begin
            stage4_ab <= stage3_ab;
            stage4_cd <= stage3_cd;
        end
    end
    
    // Stage 5: Final AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_abcd <= 1'b0;
        end else begin
            stage5_abcd <= stage4_ab & stage4_cd;
        end
    end
    
    // Stage 6: Register final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage6_abcd <= 1'b0;
        end else begin
            stage6_abcd <= stage5_abcd;
        end
    end
    
    // Final stage: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage6_abcd;  // Removed delay for better timing
        end
    end

endmodule