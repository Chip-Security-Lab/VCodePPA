//SystemVerilog
module or_gate_2input_1bit_always (
    input  wire clk,        // Clock input
    input  wire rst_n,      // Active-low reset
    input  wire a_in,       // First input operand
    input  wire b_in,       // Second input operand
    output reg  result_out  // Final result output
);

    // Pipeline stage 1: Input registration
    reg a_reg, b_reg;
    
    // Pipeline stage 2: Computation
    reg computation_result;
    
    // Multi-stage pipeline implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            computation_result <= 1'b0;
            result_out <= 1'b0;
        end else begin
            // Stage 1: Register inputs
            a_reg <= a_in;
            b_reg <= b_in;
            
            // Stage 2: Perform OR operation
            computation_result <= a_reg | b_reg;
            
            // Stage 3: Register output
            result_out <= computation_result;
        end
    end
    
endmodule