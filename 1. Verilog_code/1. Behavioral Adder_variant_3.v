// Top level module that instantiates submodules
module adder_behavioral (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] sum,
    output       carry
);
    // Internal signals
    wire [3:0] sum_internal;
    wire carry_internal;
    
    // Instantiate sum computation submodule
    sum_calculator sum_calc (
        .a(a),
        .b(b),
        .sum(sum_internal)
    );
    
    // Instantiate carry generator submodule
    carry_generator carry_gen (
        .a(a),
        .b(b),
        .carry(carry_internal)
    );
    
    // Connect outputs
    assign sum = sum_internal;
    assign carry = carry_internal;
    
endmodule

// Submodule for calculating sum bits
module sum_calculator (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] sum
);
    // Calculate sum without carry
    assign sum = a ^ b ^ {1'b0, (a[2:0] & b[2:0])};
    
endmodule

// Submodule for generating carry bit
module carry_generator (
    input  [3:0] a,
    input  [3:0] b,
    output       carry
);
    // Generate carry out
    assign carry = (a[3] & b[3]) | ((a[3] | b[3]) & (a[2] & b[2])) | 
                  ((a[3] | b[3] | (a[2] | b[2])) & (a[1] & b[1])) |
                  ((a[3] | b[3] | (a[2] | b[2]) | (a[1] | b[1])) & (a[0] & b[0]));
    
endmodule