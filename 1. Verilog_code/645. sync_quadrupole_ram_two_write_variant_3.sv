//SystemVerilog
module sync_quadrupole_ram_two_write #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_next_a, ram_next_b, ram_next_c, ram_next_d;
    reg [DATA_WIDTH-1:0] ram_curr_a, ram_curr_b, ram_curr_c, ram_curr_d;
    wire [DATA_WIDTH-1:0] diff_a, diff_b, diff_c, diff_d;
    wire [DATA_WIDTH-1:0] sel_a, sel_b, sel_c, sel_d;
    wire [DATA_WIDTH:0] carry_a, carry_b, carry_c, carry_d;

    // 先行借位减法器模块
    carry_lookahead_subtractor #(DATA_WIDTH) sub_a (
        .a(din_a),
        .b(ram[addr_a]),
        .diff(diff_a),
        .carry(carry_a)
    );

    carry_lookahead_subtractor #(DATA_WIDTH) sub_b (
        .a(din_b),
        .b(ram[addr_b]),
        .diff(diff_b),
        .carry(carry_b)
    );

    carry_lookahead_subtractor #(DATA_WIDTH) sub_c (
        .a(din_c),
        .b(ram[addr_c]),
        .diff(diff_c),
        .carry(carry_c)
    );

    carry_lookahead_subtractor #(DATA_WIDTH) sub_d (
        .a(din_d),
        .b(ram[addr_d]),
        .diff(diff_d),
        .carry(carry_d)
    );

    // 选择逻辑
    assign sel_a = carry_a[DATA_WIDTH] ? ~diff_a + 1 : diff_a;
    assign sel_b = carry_b[DATA_WIDTH] ? ~diff_b + 1 : diff_b;
    assign sel_c = carry_c[DATA_WIDTH] ? ~diff_c + 1 : diff_c;
    assign sel_d = carry_d[DATA_WIDTH] ? ~diff_d + 1 : diff_d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
            ram_curr_a <= 0;
            ram_curr_b <= 0;
            ram_curr_c <= 0;
            ram_curr_d <= 0;
        end else begin
            if (we_a) ram[addr_a] <= sel_a;
            if (we_b) ram[addr_b] <= sel_b;
            if (we_c) ram[addr_c] <= sel_c;
            if (we_d) ram[addr_d] <= sel_d;

            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
            dout_c <= ram[addr_c];
            dout_d <= ram[addr_d];
        end
    end
endmodule

module carry_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff,
    output wire [WIDTH:0] carry
);

    wire [WIDTH-1:0] b_comp = ~b;
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;

    // 生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sub
            assign g[i] = a[i] & b_comp[i];
            assign p[i] = a[i] ^ b_comp[i];
        end
    endgenerate

    // 先行进位计算
    assign c[0] = 1'b1;  // 初始借位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    // 计算差值
    assign diff = p ^ c[WIDTH-1:0];
    assign carry = c;
endmodule