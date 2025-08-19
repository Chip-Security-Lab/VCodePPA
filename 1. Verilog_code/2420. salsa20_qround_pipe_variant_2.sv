//SystemVerilog
module salsa20_qround_pipe (
    input clk, en,
    input [31:0] a, b, c, d,
    output reg [31:0] a_out, d_out
);
    // Stage 1 registers (at input)
    reg [31:0] a_reg, b_reg, c_reg, d_reg;
    
    // Intermediate results (without registers)
    wire [31:0] add_result;
    wire [31:0] rot7_result;
    wire [31:0] add_result2;
    wire [31:0] rot9_result;
    wire [31:0] c_xor_rot9;
    
    // Stage 2 registers (before output)
    reg [31:0] a_reg2, c_xor_rot9_reg, d_reg2;
    
    // Combinational logic moved before registers
    assign add_result = a_reg + d_reg;
    assign rot7_result = (add_result <<< 7);
    assign add_result2 = b_reg + rot7_result;
    assign rot9_result = (add_result2 + a_reg) <<< 9;
    assign c_xor_rot9 = c_reg ^ rot9_result;
    
    always @(posedge clk) begin
        if (en) begin
            // Stage 1: Register inputs
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            
            // Stage 2: Register intermediate results before final outputs
            a_reg2 <= a_reg;
            c_xor_rot9_reg <= c_xor_rot9;
            d_reg2 <= d_reg;
            
            // Final outputs (minimal logic after registers)
            a_out <= a_reg2 ^ c_xor_rot9_reg;
            d_out <= d_reg2 + c_xor_rot9_reg;
        end
    end
endmodule