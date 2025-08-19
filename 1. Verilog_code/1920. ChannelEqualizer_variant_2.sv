//SystemVerilog
module ChannelEqualizer #(parameter WIDTH=8) (
    input clk,
    input signed [WIDTH-1:0] rx_sample,
    output reg [WIDTH-1:0] eq_output
);
    reg signed [WIDTH-1:0] taps [0:4];
    integer i;
    reg signed [WIDTH+3:0] eq_sum_reg;

    wire signed [WIDTH-1:0] taps_next [0:4];
    wire signed [WIDTH+3:0] eq_sum_next;

    assign taps_next[0] = rx_sample;
    assign taps_next[1] = taps[0];
    assign taps_next[2] = taps[1];
    assign taps_next[3] = taps[2];
    assign taps_next[4] = taps[3];

    wire signed [WIDTH+3:0] mult0, mult1, mult2, mult3;
    assign mult0 = taps_next[0] * (-1);
    assign mult1 = taps_next[1] * 3;
    assign mult2 = taps_next[2] * 3;
    assign mult3 = taps_next[3] * (-1);

    // 8-bit Parallel Prefix Adder for four operands
    wire signed [WIDTH+3:0] sum_stage1_0, sum_stage1_1;
    wire signed [WIDTH+3:0] sum_stage2;

    ParallelPrefixAdder8 #(.WIDTH(WIDTH+4)) adder_stage1_0 (
        .a(mult0),
        .b(mult1),
        .sum(sum_stage1_0)
    );

    ParallelPrefixAdder8 #(.WIDTH(WIDTH+4)) adder_stage1_1 (
        .a(mult2),
        .b(mult3),
        .sum(sum_stage1_1)
    );

    ParallelPrefixAdder8 #(.WIDTH(WIDTH+4)) adder_stage2 (
        .a(sum_stage1_0),
        .b(sum_stage1_1),
        .sum(eq_sum_next)
    );

    always @(posedge clk) begin
        for (i = 0; i < 5; i = i + 1) begin
            taps[i] <= taps_next[i];
        end
        eq_sum_reg <= eq_sum_next;
        eq_output <= eq_sum_reg >>> 2;
    end
endmodule

module ParallelPrefixAdder8 #(parameter WIDTH=12) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;

    assign g = a & b;
    assign p = a ^ b;
    assign c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : generate_stage
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    assign sum = p ^ c[WIDTH-1:0];
endmodule