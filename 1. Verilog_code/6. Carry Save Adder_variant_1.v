// Top level module
module carry_save_adder_top (
    input  [3:0] a, b, c,
    output [3:0] sum,
    output [3:0] carry
);

    // Internal signals
    wire [3:0] partial_sum;
    wire [3:0] partial_carry;
    
    // Instantiate partial sum calculation module
    partial_sum_calc partial_sum_calc_inst (
        .a(a),
        .b(b),
        .partial_sum(partial_sum)
    );

    // Instantiate final sum calculation module
    final_sum_calc final_sum_calc_inst (
        .partial_sum(partial_sum),
        .c(c),
        .sum(sum)
    );

    // Instantiate carry calculation module
    carry_calc carry_calc_inst (
        .a(a),
        .b(b),
        .c(c),
        .carry(carry)
    );

endmodule

// Partial sum calculation submodule
module partial_sum_calc (
    input  [3:0] a, b,
    output [3:0] partial_sum
);
    assign partial_sum = a ^ b;
endmodule

// Final sum calculation submodule
module final_sum_calc (
    input  [3:0] partial_sum, c,
    output [3:0] sum
);
    assign sum = partial_sum ^ c;
endmodule

// Carry calculation submodule
module carry_calc (
    input  [3:0] a, b, c,
    output [3:0] carry
);
    wire [3:0] ab_carry;
    wire [3:0] bc_carry;
    wire [3:0] ac_carry;
    
    assign ab_carry = a & b;
    assign bc_carry = b & c;
    assign ac_carry = a & c;
    assign carry = ab_carry | bc_carry | ac_carry;
endmodule