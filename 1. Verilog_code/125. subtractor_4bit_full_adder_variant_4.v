module subtractor_4bit_conditional_sum (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_complement;
    wire [3:0] sum_with_carry;
    wire [3:0] sum_without_carry;
    wire [3:0] carry_chain;
    
    assign b_complement = ~b;
    
    // Generate sum with carry=1
    assign sum_with_carry[0] = a[0] ^ b_complement[0] ^ 1'b1;
    assign carry_chain[0] = (a[0] & b_complement[0]) | (a[0] & 1'b1) | (b_complement[0] & 1'b1);
    
    assign sum_with_carry[1] = a[1] ^ b_complement[1] ^ carry_chain[0];
    assign carry_chain[1] = (a[1] & b_complement[1]) | (a[1] & carry_chain[0]) | (b_complement[1] & carry_chain[0]);
    
    assign sum_with_carry[2] = a[2] ^ b_complement[2] ^ carry_chain[1];
    assign carry_chain[2] = (a[2] & b_complement[2]) | (a[2] & carry_chain[1]) | (b_complement[2] & carry_chain[1]);
    
    assign sum_with_carry[3] = a[3] ^ b_complement[3] ^ carry_chain[2];
    assign carry_chain[3] = (a[3] & b_complement[3]) | (a[3] & carry_chain[2]) | (b_complement[3] & carry_chain[2]);
    
    // Generate sum with carry=0
    assign sum_without_carry[0] = a[0] ^ b_complement[0] ^ 1'b0;
    assign sum_without_carry[1] = a[1] ^ b_complement[1] ^ (a[0] & b_complement[0]);
    assign sum_without_carry[2] = a[2] ^ b_complement[2] ^ ((a[1] & b_complement[1]) | (a[1] & (a[0] & b_complement[0])) | (b_complement[1] & (a[0] & b_complement[0])));
    assign sum_without_carry[3] = a[3] ^ b_complement[3] ^ ((a[2] & b_complement[2]) | (a[2] & ((a[1] & b_complement[1]) | (a[1] & (a[0] & b_complement[0])) | (b_complement[1] & (a[0] & b_complement[0])))) | (b_complement[2] & ((a[1] & b_complement[1]) | (a[1] & (a[0] & b_complement[0])) | (b_complement[1] & (a[0] & b_complement[0])))));
    
    // Select final result based on carry chain
    assign diff = carry_chain[3] ? sum_with_carry : sum_without_carry;
    assign borrow = carry_chain[3];
endmodule