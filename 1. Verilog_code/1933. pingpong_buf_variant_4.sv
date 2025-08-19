//SystemVerilog
module pingpong_buf #(parameter DW=16) (
    input clk, switch,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] buf1, buf2;
    reg sel;
    reg [DW-1:0] din_reg;

    always @(posedge clk) begin
        din_reg <= din;
    end

    wire [7:0] a_sub_b;
    wire borrow_out;

    parallel_prefix_subtractor_8bit u_pps8 (
        .a   (buf1[7:0]),
        .b   (buf2[7:0]),
        .diff(a_sub_b),
        .borrow_out(borrow_out)
    );

    always @(posedge clk) begin
        if(switch) begin
            dout <= sel ? {buf1[DW-1:8], a_sub_b} : buf2;
            sel <= !sel;
        end else begin
            if(sel) 
                buf2 <= din_reg;
            else 
                buf1 <= din_reg;
        end
    end
endmodule

module parallel_prefix_subtractor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff,
    output       borrow_out
);
    wire [7:0] g, p, x;
    wire [7:0] borrow;

    assign x = b ^ 8'hFF; // 2's complement: invert b
    assign p = a ^ x;
    assign g = (~a) & x;

    // Kogge-Stone prefix computation for borrows
    wire [7:0] c;
    assign c[0] = 1'b1; // Initial borrow-in for subtraction (a - b = a + (~b) + 1)

    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    wire [7:0] g3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign g3[7] = g2[7] | (p2[7] & g2[3]);

    // Borrow computation
    assign borrow[0] = ~c[0];
    assign borrow[1] = g[0] | (p[0] & ~c[0]);
    assign borrow[2] = g1[1] | (p1[1] & ~c[0]);
    assign borrow[3] = g2[2] | (p2[2] & ~c[0]);
    assign borrow[4] = g3[4] | (p2[4] & ~c[0]);
    assign borrow[5] = g3[5] | (p2[5] & ~c[0]);
    assign borrow[6] = g3[6] | (p2[6] & ~c[0]);
    assign borrow[7] = g3[7] | (p2[7] & ~c[0]);

    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ ~borrow[1];
    assign diff[2] = p[2] ^ ~borrow[2];
    assign diff[3] = p[3] ^ ~borrow[3];
    assign diff[4] = p[4] ^ ~borrow[4];
    assign diff[5] = p[5] ^ ~borrow[5];
    assign diff[6] = p[6] ^ ~borrow[6];
    assign diff[7] = p[7] ^ ~borrow[7];

    assign borrow_out = borrow[7];
endmodule