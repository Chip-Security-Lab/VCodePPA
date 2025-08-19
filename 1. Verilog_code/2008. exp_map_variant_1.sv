//SystemVerilog
module exp_map #(parameter W=16)(input [W-1:0] x, output [W-1:0] y);
    wire [W-5:0] shift_amount;
    wire [3:0]   lower_nibble;
    wire [W-1:0] one_shifted;
    wire [W-1:0] lower_shifted;
    wire [3:0]   lower_shifted_4b;
    wire [3:0]   prefix_sub_result;
    wire         prefix_borrow_out;
    wire [W-1:0] lower_shifted_ext;
    wire [W-1:0] sum_result;

    assign shift_amount = x[W-1:4];
    assign lower_nibble = x[3:0];
    assign one_shifted = 1 << shift_amount;

    assign lower_shifted_4b = lower_nibble << (shift_amount - 4);

    parallel_prefix_subtractor_4bit u_pps4 (
        .a(lower_shifted_4b),
        .b(4'b0000),
        .diff(prefix_sub_result),
        .borrow_out(prefix_borrow_out)
    );

    assign lower_shifted_ext = { {(W-4){1'b0}}, prefix_sub_result };

    assign y = one_shifted + lower_shifted_ext;
endmodule

module parallel_prefix_subtractor_4bit (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] diff,
    output       borrow_out
);
    wire [3:0] g, p, c;

    // Generate and Propagate signals for subtraction
    assign g = (~a) & b;       // generate borrow
    assign p = ~(a ^ b);       // propagate borrow

    // Prefix computation (Kogge-Stone style for borrow chain)
    // Borrow in is 0 for LSB
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

    assign diff[0] = a[0] ^ b[0];
    assign diff[1] = a[1] ^ b[1] ^ c[0];
    assign diff[2] = a[2] ^ b[2] ^ c[1];
    assign diff[3] = a[3] ^ b[3] ^ c[2];

    assign borrow_out = c[3];
endmodule