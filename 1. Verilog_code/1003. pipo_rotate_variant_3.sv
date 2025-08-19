//SystemVerilog
module pipo_rotate #(
    parameter WIDTH = 16
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_load,
    input wire i_shift,
    input wire i_dir,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data
);

    // 8-bit parallel prefix subtractor instantiation
    // Only used for WIDTH == 16, else default rotate
    wire [7:0] sub_a, sub_b;
    wire sub_borrow_in;
    wire [7:0] sub_diff;
    wire sub_borrow_out;

    assign sub_a = o_data[15:8];
    assign sub_b = o_data[7:0];
    assign sub_borrow_in = 1'b0;

    parallel_prefix_subtractor_8bit u_pps8 (
        .a(sub_a),
        .b(sub_b),
        .bin(sub_borrow_in),
        .diff(sub_diff),
        .bout(sub_borrow_out)
    );

    always @(posedge i_clk) begin
        if (i_rst)
            o_data <= {WIDTH{1'b0}};
        else if (i_load)
            o_data <= i_data;
        else if (i_shift) begin
            if (i_dir)
                o_data <= {o_data[WIDTH-2:0], o_data[WIDTH-1]};
            else if (WIDTH == 16)
                o_data <= {sub_diff, o_data[15:8]};
            else
                o_data <= {o_data[0], o_data[WIDTH-1:1]};
        end
    end

endmodule

module parallel_prefix_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       bin,
    output wire [7:0] diff,
    output wire       bout
);
    wire [7:0] g, p;
    wire [7:0] c;

    assign g = ~a & b;       // Generate: borrow
    assign p = ~(a ^ b);     // Propagate: no borrow if both bits are equal

    // Level 0: initial borrow (c[0])
    assign c[0] = bin;

    // Parallel prefix computation (Kogge-Stone style)
    // Level 1
    wire [7:0] b1;
    assign b1[0] = g[0] | (p[0] & c[0]);
    assign b1[1] = g[1] | (p[1] & c[0]);
    assign b1[2] = g[2] | (p[2] & c[1]);
    assign b1[3] = g[3] | (p[3] & c[2]);
    assign b1[4] = g[4] | (p[4] & c[3]);
    assign b1[5] = g[5] | (p[5] & c[4]);
    assign b1[6] = g[6] | (p[6] & c[5]);
    assign b1[7] = g[7] | (p[7] & c[6]);

    // Level 2: build carries
    assign c[1] = b1[0];
    assign c[2] = b1[1];
    assign c[3] = b1[2];
    assign c[4] = b1[3];
    assign c[5] = b1[4];
    assign c[6] = b1[5];
    assign c[7] = b1[6];

    // Difference bits
    assign diff[0] = a[0] ^ b[0] ^ c[0];
    assign diff[1] = a[1] ^ b[1] ^ c[1];
    assign diff[2] = a[2] ^ b[2] ^ c[2];
    assign diff[3] = a[3] ^ b[3] ^ c[3];
    assign diff[4] = a[4] ^ b[4] ^ c[4];
    assign diff[5] = a[5] ^ b[5] ^ c[5];
    assign diff[6] = a[6] ^ b[6] ^ c[6];
    assign diff[7] = a[7] ^ b[7] ^ c[7];

    assign bout = b1[7];

endmodule