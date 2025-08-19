module wallace_multiplier_16bit(
    input [15:0] a,
    input [15:0] b,
    output [31:0] product
);
    // Partial products generation
    wire [15:0] pp [15:0];
    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin: pp_gen
            assign pp[i] = a & {16{b[i]}};
        end
    endgenerate

    // Stage 1: First level of reduction
    wire [15:0] s1 [7:0];
    wire [15:0] c1 [7:0];
    genvar j;
    generate
        for(j=0; j<8; j=j+1) begin: stage1
            assign s1[j] = pp[2*j] ^ pp[2*j+1];
            assign c1[j] = pp[2*j] & pp[2*j+1];
        end
    endgenerate

    // Stage 2: Second level of reduction
    wire [15:0] s2 [3:0];
    wire [15:0] c2 [3:0];
    genvar k;
    generate
        for(k=0; k<4; k=k+1) begin: stage2
            assign s2[k] = s1[2*k] ^ s1[2*k+1] ^ c1[2*k];
            assign c2[k] = (s1[2*k] & s1[2*k+1]) | (s1[2*k] & c1[2*k]) | (s1[2*k+1] & c1[2*k]);
        end
    endgenerate

    // Stage 3: Third level of reduction
    wire [15:0] s3 [1:0];
    wire [15:0] c3 [1:0];
    genvar l;
    generate
        for(l=0; l<2; l=l+1) begin: stage3
            assign s3[l] = s2[2*l] ^ s2[2*l+1] ^ c2[2*l];
            assign c3[l] = (s2[2*l] & s2[2*l+1]) | (s2[2*l] & c2[2*l]) | (s2[2*l+1] & c2[2*l]);
        end
    endgenerate

    // Final stage: Final addition
    wire [15:0] sum;
    wire [15:0] carry;
    assign sum = s3[0] ^ s3[1] ^ c3[0];
    assign carry = (s3[0] & s3[1]) | (s3[0] & c3[0]) | (s3[1] & c3[0]);

    // Final product assembly
    assign product = {carry, sum};
endmodule