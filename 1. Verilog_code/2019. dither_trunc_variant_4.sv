//SystemVerilog

module dither_trunc #(parameter W=16) (
    input  [W+3:0] in,
    output [W-1:0] out
);
    reg [2:0] lfsr_reg = 3'b101;
    wire [2:0] lfsr_next;
    wire [W-1:0] trunc_val;
    wire        add_carry;
    wire [W-1:0] sum;

    assign lfsr_next = {lfsr_reg[1:0], lfsr_reg[2] ^ lfsr_reg[1]};

    always @(in or lfsr_reg) begin
        lfsr_reg <= lfsr_next;
    end

    assign trunc_val = in[W+3:4];
    assign add_carry = (in[3:0] > lfsr_reg);

    kogge_stone_adder_4bit #(.WIDTH(W)) kogge_stone_adder_inst (
        .a(trunc_val),
        .b({{W-1{1'b0}}, add_carry}),
        .sum(sum)
    );

    assign out = sum;
endmodule

module kogge_stone_adder_4bit #(parameter WIDTH=4) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);

    wire [WIDTH-1:0] g_level0, p_level0;
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH-1:0] g_level2, p_level2;
    wire [WIDTH-1:0] g_level3;
    wire [WIDTH:0]   carry;

    assign g_level0 = a & b;
    assign p_level0 = a ^ b;

    // Stage 1
    assign g_level1[0] = g_level0[0];
    assign p_level1[0] = p_level0[0];
    assign g_level1[1] = g_level0[1] | (p_level0[1] & g_level0[0]);
    assign p_level1[1] = p_level0[1] & p_level0[0];
    assign g_level1[2] = g_level0[2] | (p_level0[2] & g_level0[1]);
    assign p_level1[2] = p_level0[2] & p_level0[1];
    assign g_level1[3] = g_level0[3] | (p_level0[3] & g_level0[2]);
    assign p_level1[3] = p_level0[3] & p_level0[2];

    // Stage 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];

    // Stage 3
    assign g_level3[0] = g_level2[0];
    assign g_level3[1] = g_level2[1];
    assign g_level3[2] = g_level2[2];
    assign g_level3[3] = g_level2[3] | (p_level2[3] & g_level2[0]);

    // Carry generation
    assign carry[0] = 1'b0;
    assign carry[1] = g_level0[0] | (p_level0[0] & carry[0]);
    assign carry[2] = g_level1[1] | (p_level1[1] & carry[0]);
    assign carry[3] = g_level2[2] | (p_level2[2] & carry[0]);
    assign carry[4] = g_level3[3] | (p_level2[3] & carry[0]);

    assign sum = p_level0 ^ carry[WIDTH-1:0];

endmodule