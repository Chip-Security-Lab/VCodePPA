//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File Name: multi_stage_xnor.v
// Engineer: AI Engineer
// Description: Pipelined XNOR operation with improved data path organization
//              and optimized signal flow for better timing and area usage
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module multi_stage_xnor (
    input  wire        clk,          // System clock
    input  wire        rst_n,        // Active low reset
    input  wire [3:0]  data_a,       // Input operand A
    input  wire [3:0]  data_b,       // Input operand B
    output reg  [3:0]  result        // XNOR result
);

    // Stage 1: Register inputs
    reg [3:0] data_a_reg, data_b_reg;
    
    // Stage 2: Compute XOR and register intermediate results
    reg [3:0] xor_result;
    
    // Stage 3: Compute final XNOR result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            data_a_reg <= 4'b0;
            data_b_reg <= 4'b0;
            xor_result <= 4'b0;
            result     <= 4'b0;
        end else begin
            // Stage 1: Register inputs
            data_a_reg <= data_a;
            data_b_reg <= data_b;
            
            // Stage 2: Compute XOR (bit-wise) and register results
            xor_result[0] <= data_a_reg[0] ^ data_b_reg[0];
            xor_result[1] <= data_a_reg[1] ^ data_b_reg[1];
            xor_result[2] <= data_a_reg[2] ^ data_b_reg[2];
            xor_result[3] <= data_a_reg[3] ^ data_b_reg[3];
            
            // Stage 3: Compute XNOR (complement of XOR)
            result[0] <= ~xor_result[0];
            result[1] <= ~xor_result[1];
            result[2] <= ~xor_result[2];
            result[3] <= ~xor_result[3];
        end
    end

endmodule