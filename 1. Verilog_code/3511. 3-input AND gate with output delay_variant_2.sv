//SystemVerilog
// 3-input AND gate with pipelined structure
module and_gate_3_delay (
    input wire a,          // Input A
    input wire b,          // Input B
    input wire c,          // Input C
    input wire clk,        // Clock input
    input wire reset_n,    // Active low reset
    output reg y           // Output Y
);
    // Pipeline registers for input data path
    reg a_reg, b_reg, c_reg;
    reg ab_and_stage1;     // First pipeline stage result
    
    // Input registration stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            c_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end
    
    // Stage 1: First AND operation (a & b)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ab_and_stage1 <= 1'b0;
        end else begin
            ab_and_stage1 <= a_reg & b_reg;
        end
    end
    
    // Stage 2: Final AND operation ((a & b) & c)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            y <= 1'b0;
        end else begin
            y <= ab_and_stage1 & c_reg;
        end
    end
    
endmodule