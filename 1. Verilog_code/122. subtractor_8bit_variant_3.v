module manchester_carry_chain_adder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    wire [7:0] g, p;
    wire [7:0] carry;
    
    // Generate and Propagate
    assign g = a & b;
    assign p = a ^ b;
    
    // Manchester Carry Chain
    assign carry[0] = 1'b0;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & carry[1]);
    assign carry[3] = g[2] | (p[2] & carry[2]);
    assign carry[4] = g[3] | (p[3] & carry[3]);
    assign carry[5] = g[4] | (p[4] & carry[4]);
    assign carry[6] = g[5] | (p[5] & carry[5]);
    assign carry[7] = g[6] | (p[6] & carry[6]);
    
    // Final Sum
    assign sum = p ^ carry;
endmodule

module subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);
    wire [7:0] b_comp;
    wire [7:0] b_plus_1;
    wire [7:0] b_twos_comp;
    
    assign b_comp = ~b;
    assign b_plus_1 = b_comp + 8'b00000001;
    assign b_twos_comp = b_plus_1;
    
    manchester_carry_chain_adder adder (
        .a(a),
        .b(b_twos_comp),
        .sum(diff)
    );
endmodule