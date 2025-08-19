//SystemVerilog
module wallace_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Partial products generation with optimized structure
    wire [7:0] pp [7:0];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            assign pp[i] = a & {8{b[i]}};
        end
    endgenerate

    // First stage compression with optimized grouping
    wire [8:0] s1_0, c1_0;
    wire [8:0] s1_1, c1_1;
    wire [8:0] s1_2, c1_2;
    
    // Second stage compression with balanced tree structure
    wire [9:0] s2_0, c2_0;
    wire [9:0] s2_1, c2_1;
    
    // Third stage compression
    wire [10:0] s3_0, c3_0;
    
    // Final stage with optimized addition
    wire [15:0] sum, carry;
    
    // First stage compression with optimized grouping
    compressor_3_2 comp1_0 (
        .a(pp[0]),
        .b(pp[1]),
        .c(pp[2]),
        .sum(s1_0),
        .carry(c1_0)
    );
    
    compressor_3_2 comp1_1 (
        .a(pp[3]),
        .b(pp[4]),
        .c(pp[5]),
        .sum(s1_1),
        .carry(c1_1)
    );
    
    compressor_3_2 comp1_2 (
        .a(pp[6]),
        .b(pp[7]),
        .c(8'b0),
        .sum(s1_2),
        .carry(c1_2)
    );
    
    // Second stage compression with balanced tree
    compressor_3_2 comp2_0 (
        .a(s1_0),
        .b(s1_1),
        .c(s1_2),
        .sum(s2_0),
        .carry(c2_0)
    );
    
    compressor_3_2 comp2_1 (
        .a(c1_0),
        .b(c1_1),
        .c(c1_2),
        .sum(s2_1),
        .carry(c2_1)
    );
    
    // Third stage compression with optimized carry handling
    compressor_3_2 comp3_0 (
        .a(s2_0),
        .b(s2_1),
        .c(10'b0),
        .sum(s3_0),
        .carry(c3_0)
    );
    
    // Final addition with optimized carry propagation
    assign sum = {s3_0, 5'b0};
    assign carry = {c3_0, 5'b0};
    assign product = sum + carry;
endmodule

module compressor_3_2 (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    output reg [8:0] sum,
    output reg [8:0] carry
);
    // Optimized compressor logic with reduced gate count
    wire [7:0] ab, bc, ac;
    wire [7:0] temp_sum;
    
    assign ab = a & b;
    assign bc = b & c;
    assign ac = a & c;
    assign temp_sum = a ^ b;
    
    always @* begin
        sum = temp_sum ^ c;
        carry = ab | bc | ac;
    end
endmodule