//SystemVerilog
// 4-input AND gate with pipelined structure
module and_gate_4 (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active low reset
    input  wire a,      // Input A
    input  wire b,      // Input B
    input  wire c,      // Input C
    input  wire d,      // Input D
    output reg  y       // Output Y (registered)
);

    // Stage 1: First level AND operations
    reg stage1_ab;
    reg stage1_cd;
    
    // Stage 2: Final AND operation
    reg stage2_result;
    
    // Pipeline Stage 1: Calculate partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_cd <= 1'b0;
        end else begin
            stage1_ab <= a & b;  // Partial product AB
            stage1_cd <= c & d;  // Partial product CD
        end
    end
    
    // Pipeline Stage 2: Calculate final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_ab & stage1_cd;  // Final AND operation
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage2_result;  // Register output
        end
    end

endmodule