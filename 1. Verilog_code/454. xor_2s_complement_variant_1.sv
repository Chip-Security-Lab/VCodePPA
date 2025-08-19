//SystemVerilog
// SystemVerilog
// Top-level module with optimized dataflow and balanced critical paths
module xor_2s_complement (
    input  logic        clk,        // Clock signal
    input  logic        rst_n,      // Reset signal
    input  logic [3:0]  data_in,    // Input data
    output logic [3:0]  xor_out     // Output result
);
    // Constant mask definition - no need to store in register
    localparam MASK_VALUE = 4'b1111;
    
    // Optimized pipeline structure with fewer stages
    logic [3:0] data_in_reg;
    logic [3:0] xor_result;
    
    // First pipeline stage - register inputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 4'b0000;
        end else begin
            data_in_reg <= data_in;
        end
    end
    
    // Compute XOR with constant at second stage
    // Direct XOR with constant reduces logic depth
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out <= 4'b0000;
        end else begin
            // Perform XOR directly with constant to eliminate intermediate stage
            xor_out <= data_in_reg ^ MASK_VALUE;
        end
    end
    
endmodule