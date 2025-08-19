//SystemVerilog
module adder_5 (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);

    // Wires for Generate (G) and Propagate (P) signals for each bit
    wire [7:0] g, p;

    // Wires for prefix stages
    wire [7:0] G1, P1; // Stage 1 (distance 1)
    wire [7:0] G2, P2; // Stage 2 (distance 2)
    wire [7:0] G3, P3; // Stage 3 (distance 4)

    // Wires for carries
    // c[0] = cin
    // c[1]..c[7] = carries into bits 1..7
    // c[8] = cout
    wire [8:0] c;

    // Stage 0: Bit-level G and P
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_stage0
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Stage 1: Distance 1 prefix
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_stage1
            if (i == 0) begin
                assign G1[i] = g[i];
                assign P1[i] = p[i];
            end else begin
                assign G1[i] = g[i] | (p[i] & g[i-1]);
                assign P1[i] = p[i] & p[i-1];
            end
        end
    endgenerate

    // Stage 2: Distance 2 prefix
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_stage2
            if (i < 2) begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end else begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-2]);
                assign P2[i] = P1[i] & P1[i-2];
            end
        end
    endgenerate

    // Stage 3: Distance 4 prefix
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_stage3
            if (i < 4) begin
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end else begin
                assign G3[i] = G2[i] | (P2[i] & G2[i-4]);
                assign P3[i] = P2[i] & P2[i-4];
            end
        end
    endgenerate

    // Carry calculation
    // c[0] is the input carry
    assign c[0] = cin;
    // c[i+1] is the carry into bit i+1, calculated from G and P of bit i and cin
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_carries
            assign c[i+1] = G3[i] | (P3[i] & cin);
        end
    endgenerate

    // Sum calculation
    // sum[i] = p[i] ^ c[i]
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    // Cout is the carry out from the most significant bit (carry into bit 8)
    assign cout = c[8];

endmodule