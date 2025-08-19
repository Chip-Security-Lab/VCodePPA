//SystemVerilog
module StageEnabledShifter #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH-1:0] stage_en,
    input serial_in,
    output [WIDTH-1:0] parallel_out
);

    reg [WIDTH-1:0] reg_parallel_out;
    reg [WIDTH-1:0] reg_adder_a;
    reg [WIDTH-1:0] reg_adder_b;
    reg reg_serial_in;
    wire [WIDTH-1:0] adder_sum;

    assign parallel_out = reg_parallel_out;

    // Register adder_a and adder_b inputs (move register before adder)
    always @(posedge clk) begin
        reg_adder_a <= reg_parallel_out;
        reg_adder_b <= {reg_parallel_out[WIDTH-2:0], reg_serial_in};
        reg_serial_in <= serial_in;
    end

    ParallelPrefixAdder8 ppa_inst (
        .a(reg_adder_a),
        .b(reg_adder_b),
        .sum(adder_sum)
    );

    integer j;
    always @(posedge clk) begin
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (stage_en[j]) begin
                reg_parallel_out[j] <= adder_sum[j];
            end
        end
    end

endmodule

module ParallelPrefixAdder8 (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] sum
);
    wire [7:0] g, p;
    wire [7:0] c;

    // Generate and propagate
    assign g = a & b;
    assign p = a ^ b;

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

    // Carry chain
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g1[1] | (p1[1] & c[0]);
    assign c[3] = g2[2] | (p2[2] & c[0]);
    assign c[4] = g3[3] | (p2[3] & c[0]);
    assign c[5] = g3[4] | (p2[4] & c[0]);
    assign c[6] = g3[5] | (p2[5] & c[0]);
    assign c[7] = g3[6] | (p2[6] & c[0]);

    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];

endmodule