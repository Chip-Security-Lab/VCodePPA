//SystemVerilog
// Top-level module: bit_interleaver
module bit_interleaver #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output [2*WIDTH-1:0] interleaved_data,
    output [WIDTH:0] manchester_sum
);

    // Internal signals for submodule connections
    wire [WIDTH-1:0] interleaved_a;
    wire [WIDTH-1:0] interleaved_b;
    wire [WIDTH-1:0] manch_p;
    wire [WIDTH-1:0] manch_g;
    wire [WIDTH:0]   manch_c;

    // Interleaver submodule instantiation
    bit_interleaver_interleaver #(
        .WIDTH(WIDTH)
    ) u_interleaver (
        .data_a        (data_a),
        .data_b        (data_b),
        .interleaved_a (interleaved_a),
        .interleaved_b (interleaved_b)
    );

    // Combine interleaved_a and interleaved_b into interleaved_data
    genvar idx;
    generate
        for (idx = 0; idx < WIDTH; idx = idx + 1) begin : gen_interleaved_data
            assign interleaved_data[2*idx]   = interleaved_a[idx];
            assign interleaved_data[2*idx+1] = interleaved_b[idx];
        end
    endgenerate

    // Manchester adder submodule instantiation
    bit_interleaver_manchester_adder #(
        .WIDTH(WIDTH)
    ) u_manchester_adder (
        .data_a         (data_a),
        .data_b         (data_b),
        .manchester_sum (manchester_sum)
    );

endmodule

// -----------------------------------------------------------------------------
// Interleaver submodule: Bitwise interleaving of two input vectors
// -----------------------------------------------------------------------------
module bit_interleaver_interleaver #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output [WIDTH-1:0] interleaved_a,
    output [WIDTH-1:0] interleaved_b
);
    // Each bit of data_a and data_b is mapped to even and odd positions
    assign interleaved_a = data_a;
    assign interleaved_b = data_b;
endmodule

// -----------------------------------------------------------------------------
// Manchester Adder submodule: Carry-chain adder using Manchester carry logic
// -----------------------------------------------------------------------------
module bit_interleaver_manchester_adder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output [WIDTH:0]   manchester_sum
);

    wire [WIDTH-1:0] manch_p;
    wire [WIDTH-1:0] manch_g;
    wire [WIDTH:0]   manch_c;

    assign manch_c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : manchester_adder_chain
            assign manch_p[i] = data_a[i] ^ data_b[i];
            assign manch_g[i] = data_a[i] & data_b[i];
            assign manch_c[i+1] = (i == 0) ? (manch_g[0] | (manch_p[0] & manch_c[0]))
                                           : (manch_g[i] | (manch_p[i] & manch_c[i]));
            assign manchester_sum[i] = manch_p[i] ^ manch_c[i];
        end
    endgenerate

    assign manchester_sum[WIDTH] = manch_c[WIDTH];

endmodule