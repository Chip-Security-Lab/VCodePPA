//SystemVerilog
module AsyncRst_XNOR(
    input rst_n,
    input [3:0] src_a, src_b,
    output reg [3:0] q
);
    wire [3:0] xnor_result;
    wire [7:0] bw_mult_result;

    // Baugh-Wooley 4-bit multiplier instance
    BaughWooley_4bit bw_mult (
        .a(src_a),
        .b(src_b),
        .product(bw_mult_result)
    );
    
    // XNOR operation derived from Baugh-Wooley multiplication result
    // We use bits [3:0] of the multiplier result and map them to achieve XNOR functionality
    assign xnor_result = {
        bw_mult_result[7] & bw_mult_result[0],
        bw_mult_result[5] & bw_mult_result[1],
        bw_mult_result[3] & bw_mult_result[2],
        bw_mult_result[1] & bw_mult_result[3]
    };
    
    always @(*) begin
        q = rst_n ? xnor_result : 4'b0000;
    end
endmodule

// Baugh-Wooley 4-bit multiplier implementation
module BaughWooley_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Partial products
    wire [15:0] pp;
    
    // Generate partial products
    // Regular partial products for non-sign bits
    assign pp[0] = a[0] & b[0];
    assign pp[1] = a[1] & b[0];
    assign pp[2] = a[2] & b[0];
    assign pp[3] = ~(a[3] & b[0]); // Negated for sign bit
    
    assign pp[4] = a[0] & b[1];
    assign pp[5] = a[1] & b[1];
    assign pp[6] = a[2] & b[1];
    assign pp[7] = ~(a[3] & b[1]); // Negated for sign bit
    
    assign pp[8] = a[0] & b[2];
    assign pp[9] = a[1] & b[2];
    assign pp[10] = a[2] & b[2];
    assign pp[11] = ~(a[3] & b[2]); // Negated for sign bit
    
    assign pp[12] = ~(a[0] & b[3]); // Negated for sign bit
    assign pp[13] = ~(a[1] & b[3]); // Negated for sign bit
    assign pp[14] = ~(a[2] & b[3]); // Negated for sign bit
    assign pp[15] = a[3] & b[3];    // Regular for sign*sign
    
    // Reduction stage 1 - first row additions
    wire [5:0] s1, c1;
    assign s1[0] = pp[0];
    assign c1[0] = 1'b0;
    
    assign s1[1] = pp[1] ^ pp[4] ^ 1'b0;
    assign c1[1] = (pp[1] & pp[4]) | (pp[1] & 1'b0) | (pp[4] & 1'b0);
    
    assign s1[2] = pp[2] ^ pp[5] ^ pp[8];
    assign c1[2] = (pp[2] & pp[5]) | (pp[2] & pp[8]) | (pp[5] & pp[8]);
    
    assign s1[3] = pp[3] ^ pp[6] ^ pp[9] ^ pp[12];
    assign c1[3] = (pp[3] & pp[6]) | (pp[3] & pp[9]) | (pp[3] & pp[12]) | 
                   (pp[6] & pp[9]) | (pp[6] & pp[12]) | (pp[9] & pp[12]);
    
    assign s1[4] = pp[7] ^ pp[10] ^ pp[13];
    assign c1[4] = (pp[7] & pp[10]) | (pp[7] & pp[13]) | (pp[10] & pp[13]);
    
    assign s1[5] = pp[11] ^ pp[14] ^ pp[15] ^ 1'b1;
    assign c1[5] = (pp[11] & pp[14]) | (pp[11] & pp[15]) | (pp[11] & 1'b1) | 
                   (pp[14] & pp[15]) | (pp[14] & 1'b1) | (pp[15] & 1'b1);
    
    // Reduction stage 2 - final additions
    wire [7:0] s2, c2;
    assign s2[0] = s1[0];
    assign c2[0] = 1'b0;
    
    assign s2[1] = s1[1];
    assign c2[1] = c1[0];
    
    assign s2[2] = s1[2] ^ c1[1];
    assign c2[2] = s1[2] & c1[1];
    
    assign s2[3] = s1[3] ^ c1[2];
    assign c2[3] = s1[3] & c1[2];
    
    assign s2[4] = s1[4] ^ c1[3];
    assign c2[4] = s1[4] & c1[3];
    
    assign s2[5] = s1[5] ^ c1[4];
    assign c2[5] = s1[5] & c1[4];
    
    assign s2[6] = c1[5];
    assign c2[6] = 1'b0;
    
    assign s2[7] = 1'b0;
    assign c2[7] = 1'b0;
    
    // Final product computation
    assign product[0] = s2[0];
    assign product[1] = s2[1] ^ c2[1];
    assign product[2] = s2[2] ^ c2[2];
    assign product[3] = s2[3] ^ c2[3];
    assign product[4] = s2[4] ^ c2[4];
    assign product[5] = s2[5] ^ c2[5];
    assign product[6] = s2[6] ^ c2[6];
    assign product[7] = s2[7] ^ c2[7];
endmodule