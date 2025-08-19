module subtractor_4bit_full_adder (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff, 
    output borrow
);
    wire [3:0] b_complement;
    wire c1, c2, c3;
    
    assign b_complement = ~b;  // Get complement
    full_adder FA0 (a[0], b_complement[0], 1'b1, diff[0], c1);
    full_adder FA1 (a[1], b_complement[1], c1, diff[1], c2);
    full_adder FA2 (a[2], b_complement[2], c2, diff[2], c3);
    full_adder FA3 (a[3], b_complement[3], c3, diff[3], borrow);
endmodule

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