//SystemVerilog
module piecewise_lin #(
    parameter N = 3
)(
    input [15:0] x,
    input [15:0] knots_array [(N-1):0],
    input [15:0] slopes_array [(N-1):0],
    output [15:0] y
);
    reg [15:0] seg_sum;
    integer idx;

    wire [15:0] diff_array [0:N-1];
    wire [15:0] prod_array [0:N-1];
    wire [15:0] sum_array [0:N-1];
    wire [N-1:0] cond_array;

    // Difference calculation
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : diff_gen
            assign cond_array[i] = (x > knots_array[i]);
            assign diff_array[i] = cond_array[i] ? (brent_kung_sub_16(x, knots_array[i])) : 16'b0;
        end
    endgenerate

    // Multiplication
    generate
        for (i = 0; i < N; i = i + 1) begin : prod_gen
            assign prod_array[i] = cond_array[i] ? (slopes_array[i] * diff_array[i]) : 16'b0;
        end
    endgenerate

    // Sum all segments using Brent-Kung adder
    generate
        if (N == 1) begin
            assign y = prod_array[0];
        end else if (N == 2) begin
            brent_kung_add_16 u_add0 (.a(prod_array[0]), .b(prod_array[1]), .sum(y));
        end else if (N == 3) begin
            wire [15:0] temp_sum;
            brent_kung_add_16 u_add0 (.a(prod_array[0]), .b(prod_array[1]), .sum(temp_sum));
            brent_kung_add_16 u_add1 (.a(temp_sum), .b(prod_array[2]), .sum(y));
        end else begin
            // For N > 3, chain Brent-Kung adders as needed
            reg [15:0] temp_sum[N-2:0];
            integer j;
            always @(*) begin
                temp_sum[0] = prod_array[0];
                for (j = 1; j < N; j = j + 1) begin
                    temp_sum[j] = brent_kung_add_16(temp_sum[j-1], prod_array[j]);
                end
            end
            assign y = temp_sum[N-1];
        end
    endgenerate

    // Brent-Kung Adder for 16-bit
    function [15:0] brent_kung_sub_16;
        input [15:0] a, b;
        begin
            brent_kung_sub_16 = a - b;
        end
    endfunction
endmodule

// 16-bit Brent-Kung Adder Module
module brent_kung_add_16(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] sum
);
    wire [15:0] g, p;  // generate, propagate
    wire [15:0] c;     // carries

    assign g = a & b;
    assign p = a ^ b;

    wire [15:0] G1, P1, G2, P2, G3, P3, G4, P4;

    // Stage 1
    assign G1[0]  = g[0];
    assign P1[0]  = p[0];
    genvar i;
    generate
        for (i=1; i<16; i=i+1) begin : stage1
            assign G1[i] = g[i] | (p[i] & g[i-1]);
            assign P1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Stage 2
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    genvar j;
    generate
        for (j=2; j<16; j=j+1) begin : stage2
            assign G2[j] = G1[j] | (P1[j] & G1[j-2]);
            assign P2[j] = P1[j] & P1[j-2];
        end
    endgenerate

    // Stage 3
    assign G3[0] = G2[0];
    assign P3[0] = P2[0];
    assign G3[1] = G2[1];
    assign P3[1] = P2[1];
    assign G3[2] = G2[2];
    assign P3[2] = P2[2];
    assign G3[3] = G2[3];
    assign P3[3] = P2[3];
    genvar k;
    generate
        for (k=4; k<16; k=k+1) begin : stage3
            assign G3[k] = G2[k] | (P2[k] & G2[k-4]);
            assign P3[k] = P2[k] & P2[k-4];
        end
    endgenerate

    // Stage 4
    assign G4[0] = G3[0];
    assign P4[0] = P3[0];
    assign G4[1] = G3[1];
    assign P4[1] = P3[1];
    assign G4[2] = G3[2];
    assign P4[2] = P3[2];
    assign G4[3] = G3[3];
    assign P4[3] = P3[3];
    assign G4[4] = G3[4];
    assign P4[4] = P3[4];
    assign G4[5] = G3[5];
    assign P4[5] = P3[5];
    assign G4[6] = G3[6];
    assign P4[6] = P3[6];
    assign G4[7] = G3[7];
    assign P4[7] = P3[7];
    genvar l;
    generate
        for (l=8; l<16; l=l+1) begin : stage4
            assign G4[l] = G3[l] | (P3[l] & G3[l-8]);
            assign P4[l] = P3[l] & P3[l-8];
        end
    endgenerate

    // Carry calculation
    assign c[0] = 1'b0;
    assign c[1] = G1[0];
    assign c[2] = G2[1];
    assign c[3] = G1[2] | (P1[2] & G2[1]);
    assign c[4] = G3[3];
    assign c[5] = G1[4] | (P1[4] & G3[3]);
    assign c[6] = G2[5] | (P2[5] & G3[3]);
    assign c[7] = G1[6] | (P1[6] & G2[5] | (P1[6] & P2[5] & G3[3]));
    assign c[8] = G4[7];
    assign c[9] = G1[8] | (P1[8] & G4[7]);
    assign c[10] = G2[9] | (P2[9] & G4[7]);
    assign c[11] = G1[10] | (P1[10] & G2[9] | (P1[10] & P2[9] & G4[7]));
    assign c[12] = G3[11] | (P3[11] & G4[7]);
    assign c[13] = G1[12] | (P1[12] & G3[11] | (P1[12] & P3[11] & G4[7]));
    assign c[14] = G2[13] | (P2[13] & G3[11] | (P2[13] & P3[11] & G4[7]));
    assign c[15] = G1[14] | (P1[14] & G2[13] | (P1[14] & P2[13] & G3[11] | (P1[14] & P2[13] & P3[11] & G4[7])));

    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    assign sum[8] = p[8] ^ c[8];
    assign sum[9] = p[9] ^ c[9];
    assign sum[10] = p[10] ^ c[10];
    assign sum[11] = p[11] ^ c[11];
    assign sum[12] = p[12] ^ c[12];
    assign sum[13] = p[13] ^ c[13];
    assign sum[14] = p[14] ^ c[14];
    assign sum[15] = p[15] ^ c[15];
endmodule