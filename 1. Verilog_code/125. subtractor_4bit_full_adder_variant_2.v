module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module complement_generator (
    input [3:0] in,
    output [3:0] out
);
    assign out = ~in;
endmodule

module subtractor_4bit_full_adder (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_complement;
    wire [3:0] carry;
    
    complement_generator comp_gen (
        .in(b),
        .out(b_complement)
    );
    
    assign carry[0] = 1'b1;
    
    full_adder fa0 (
        .a(a[0]),
        .b(b_complement[0]),
        .cin(carry[0]),
        .sum(diff[0]),
        .cout(carry[1])
    );
    
    full_adder fa1 (
        .a(a[1]),
        .b(b_complement[1]),
        .cin(carry[1]),
        .sum(diff[1]),
        .cout(carry[2])
    );
    
    full_adder fa2 (
        .a(a[2]),
        .b(b_complement[2]),
        .cin(carry[2]),
        .sum(diff[2]),
        .cout(carry[3])
    );
    
    full_adder fa3 (
        .a(a[3]),
        .b(b_complement[3]),
        .cin(carry[3]),
        .sum(diff[3]),
        .cout(borrow)
    );
endmodule