//SystemVerilog
module piecewise_lin #(
    parameter N = 3
)(
    input  [15:0] x,
    input  [15:0] knots_array [(N-1):0],
    input  [15:0] slopes_array [(N-1):0],
    output [15:0] y
);

    // Intermediate signals for each segment calculation
    reg [15:0] segment_contrib [N-1:0];
    wire [15:0] segment_sum;

    integer idx;

    // Generate segment contributions
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : SEGMENT_BLOCKS
            always @(*) begin
                if (x > knots_array[i]) begin
                    segment_contrib[i] = slopes_array[i] * (x - knots_array[i]);
                end else begin
                    segment_contrib[i] = 16'd0;
                end
            end
        end
    endgenerate

    // Parallel Prefix Adder for summing segment_contrib array
    parallel_prefix_adder_16N #(.N(N)) u_parallel_prefix_adder_16N (
        .data_in(segment_contrib),
        .sum(segment_sum)
    );

    assign y = segment_sum;

endmodule

// Parallel Prefix Adder for 16-bit N inputs
module parallel_prefix_adder_16N #(
    parameter N = 3
)(
    input  [15:0] data_in [N-1:0],
    output [15:0] sum
);
    wire [15:0] prefix_sum [N:0];
    assign prefix_sum[0] = 16'd0;

    genvar k;
    generate
        for (k = 0; k < N; k = k + 1) begin : PREFIX_ADD
            parallel_prefix_adder_16 u_prefix_adder (
                .a(prefix_sum[k]),
                .b(data_in[k]),
                .sum(prefix_sum[k+1])
            );
        end
    endgenerate

    assign sum = prefix_sum[N];
endmodule

// 16-bit Kogge-Stone Parallel Prefix Adder
module parallel_prefix_adder_16 (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] sum
);
    wire [15:0] g [4:0]; // Generate
    wire [15:0] p [4:0]; // Propagate
    wire [15:0] c;       // Carry

    assign g[0] = a & b;
    assign p[0] = a ^ b;

    // Stage 1
    assign g[1][0] = g[0][0];
    assign p[1][0] = p[0][0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 16; i1 = i1 + 1) begin : G1
            assign g[1][i1] = g[0][i1] | (p[0][i1] & g[0][i1-1]);
            assign p[1][i1] = p[0][i1] & p[0][i1-1];
        end
    endgenerate

    // Stage 2
    assign g[2][0] = g[1][0];
    assign p[2][0] = p[1][0];
    assign g[2][1] = g[1][1];
    assign p[2][1] = p[1][1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 16; i2 = i2 + 1) begin : G2
            assign g[2][i2] = g[1][i2] | (p[1][i2] & g[1][i2-2]);
            assign p[2][i2] = p[1][i2] & p[1][i2-2];
        end
    endgenerate

    // Stage 3
    assign g[3][0] = g[2][0];
    assign p[3][0] = p[2][0];
    assign g[3][1] = g[2][1];
    assign p[3][1] = p[2][1];
    assign g[3][2] = g[2][2];
    assign p[3][2] = p[2][2];
    assign g[3][3] = g[2][3];
    assign p[3][3] = p[2][3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 16; i3 = i3 + 1) begin : G3
            assign g[3][i3] = g[2][i3] | (p[2][i3] & g[2][i3-4]);
            assign p[3][i3] = p[2][i3] & p[2][i3-4];
        end
    endgenerate

    // Stage 4
    assign g[4][0] = g[3][0];
    assign p[4][0] = p[3][0];
    assign g[4][1] = g[3][1];
    assign p[4][1] = p[3][1];
    assign g[4][2] = g[3][2];
    assign p[4][2] = p[3][2];
    assign g[4][3] = g[3][3];
    assign p[4][3] = p[3][3];
    assign g[4][4] = g[3][4];
    assign p[4][4] = p[3][4];
    assign g[4][5] = g[3][5];
    assign p[4][5] = p[3][5];
    assign g[4][6] = g[3][6];
    assign p[4][6] = p[3][6];
    assign g[4][7] = g[3][7];
    assign p[4][7] = p[3][7];
    genvar i4;
    generate
        for (i4 = 8; i4 < 16; i4 = i4 + 1) begin : G4
            assign g[4][i4] = g[3][i4] | (p[3][i4] & g[3][i4-8]);
            assign p[4][i4] = p[3][i4] & p[3][i4-8];
        end
    endgenerate

    // Carry calculation
    assign c[0] = 1'b0;
    genvar ic;
    generate
        for (ic = 1; ic < 16; ic = ic + 1) begin : CARRY
            assign c[ic] = g[4][ic-1];
        end
    endgenerate

    // Sum calculation
    assign sum = p[0] ^ c;

endmodule