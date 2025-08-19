//SystemVerilog
// 4-input AND gate with optimized pipelined data path
module and_gate_4 (
    input  wire clk,      // Clock input
    input  wire rst_n,    // Active-low reset
    input  wire a,        // First input
    input  wire b,        // Second input
    input  wire c,        // Third input
    input  wire d,        // Fourth input
    output wire y         // Output result
);

    // Pipeline stage registers
    reg a_reg, b_reg, c_reg, d_reg;       // Input registers
    reg stage1_ab;                         // Stage 1: A&B result
    reg stage1_cd;                         // Stage 1: C&D result
    reg stage2_result;                     // Stage 2: Final result
    
    // Input registration - improve timing on input paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            c_reg <= 1'b0;
            d_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
        end
    end
    
    // First pipeline stage - compute parallel AND operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab <= 1'b0;
            stage1_cd <= 1'b0;
        end else begin
            stage1_ab <= a_reg & b_reg;    // Compute A&B
            stage1_cd <= c_reg & d_reg;    // Compute C&D in parallel
        end
    end
    
    // Second pipeline stage - combine intermediate results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_ab & stage1_cd;
        end
    end
    
    // Output assignment
    assign y = stage2_result;

endmodule