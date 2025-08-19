//SystemVerilog
module arith_extend (
    input [3:0] operand,
    output [4:0] inc,
    output [4:0] dec
);

    // Parallel prefix adder implementation for increment operation
    wire [4:0] inc_result;
    wire [3:0] carry_propagate;
    wire [3:0] carry_generate;
    wire [3:0] carry_out;
    
    // Generate and propagate signals
    assign carry_generate = operand;
    assign carry_propagate = 4'b1111; // All bits propagate
    
    // First level of prefix computation
    wire [1:0] g1, p1;
    assign g1[0] = carry_generate[0];
    assign p1[0] = carry_propagate[0];
    assign g1[1] = carry_generate[1] | (carry_generate[0] & carry_propagate[1]);
    assign p1[1] = carry_propagate[0] & carry_propagate[1];
    
    // Second level of prefix computation
    wire [3:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = carry_generate[2] | (g1[1] & carry_propagate[2]);
    assign p2[2] = p1[1] & carry_propagate[2];
    assign g2[3] = carry_generate[3] | (g1[1] & carry_propagate[3]);
    assign p2[3] = p1[1] & carry_propagate[3];
    
    // Final carry computation
    assign carry_out[0] = g2[0];
    assign carry_out[1] = g2[1];
    assign carry_out[2] = g2[2];
    assign carry_out[3] = g2[3];
    
    // Sum computation
    assign inc_result[0] = operand[0] ^ 1'b1;
    assign inc_result[1] = operand[1] ^ carry_out[0];
    assign inc_result[2] = operand[2] ^ carry_out[1];
    assign inc_result[3] = operand[3] ^ carry_out[2];
    assign inc_result[4] = carry_out[3];
    
    // Decrement operation using the same parallel prefix adder
    wire [4:0] dec_result;
    wire [3:0] dec_carry_propagate;
    wire [3:0] dec_carry_generate;
    wire [3:0] dec_carry_out;
    
    // Generate and propagate signals for decrement
    assign dec_carry_generate = operand;
    assign dec_carry_propagate = 4'b1111;
    
    // First level of prefix computation for decrement
    wire [1:0] dec_g1, dec_p1;
    assign dec_g1[0] = dec_carry_generate[0];
    assign dec_p1[0] = dec_carry_propagate[0];
    assign dec_g1[1] = dec_carry_generate[1] | (dec_carry_generate[0] & dec_carry_propagate[1]);
    assign dec_p1[1] = dec_carry_propagate[0] & dec_carry_propagate[1];
    
    // Second level of prefix computation for decrement
    wire [3:0] dec_g2, dec_p2;
    assign dec_g2[0] = dec_g1[0];
    assign dec_p2[0] = dec_p1[0];
    assign dec_g2[1] = dec_g1[1];
    assign dec_p2[1] = dec_p1[1];
    assign dec_g2[2] = dec_carry_generate[2] | (dec_g1[1] & dec_carry_propagate[2]);
    assign dec_p2[2] = dec_p1[1] & dec_carry_propagate[2];
    assign dec_g2[3] = dec_carry_generate[3] | (dec_g1[1] & dec_carry_propagate[3]);
    assign dec_p2[3] = dec_p1[1] & dec_carry_propagate[3];
    
    // Final carry computation for decrement
    assign dec_carry_out[0] = dec_g2[0];
    assign dec_carry_out[1] = dec_g2[1];
    assign dec_carry_out[2] = dec_g2[2];
    assign dec_carry_out[3] = dec_g2[3];
    
    // Sum computation for decrement
    assign dec_result[0] = operand[0] ^ 1'b1;
    assign dec_result[1] = operand[1] ^ dec_carry_out[0];
    assign dec_result[2] = operand[2] ^ dec_carry_out[1];
    assign dec_result[3] = operand[3] ^ dec_carry_out[2];
    assign dec_result[4] = dec_carry_out[3];
    
    // Final outputs
    assign inc = inc_result;
    assign dec = dec_result;

endmodule