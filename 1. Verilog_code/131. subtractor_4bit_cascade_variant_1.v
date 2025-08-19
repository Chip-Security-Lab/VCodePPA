module twos_complement_generator (
    input [3:0] b,
    output [3:0] b_comp
);
    assign b_comp = ~b + 1'b1;
endmodule

module adder_4bit (
    input [3:0] a,
    input [3:0] b,
    output [4:0] sum
);
    assign sum = a + b;
endmodule

module subtractor_4bit_twos_complement (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_comp;
    wire [4:0] sum;
    
    twos_complement_generator comp_gen (
        .b(b),
        .b_comp(b_comp)
    );
    
    adder_4bit adder (
        .a(a),
        .b(b_comp),
        .sum(sum)
    );
    
    assign diff = sum[3:0];
    assign borrow = sum[4];
endmodule