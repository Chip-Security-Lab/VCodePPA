//SystemVerilog
module bin_to_onehot #(
    parameter BIN_WIDTH = 4
)(
    input wire [BIN_WIDTH-1:0] bin_in,
    input wire enable,
    output reg [(1<<BIN_WIDTH)-1:0] onehot_out
);
    wire [BIN_WIDTH-1:0] adder_a;
    wire [BIN_WIDTH-1:0] adder_b;
    wire adder_cin;
    wire [BIN_WIDTH-1:0] adder_sum;
    wire adder_cout;

    assign adder_a = bin_in;
    assign adder_b = {BIN_WIDTH{1'b0}};
    assign adder_cin = 1'b0;

    parallel_prefix_adder_4bit u_parallel_prefix_adder_4bit (
        .a(adder_a),
        .b(adder_b),
        .cin(adder_cin),
        .sum(adder_sum),
        .cout(adder_cout)
    );

    integer i;
    always @(*) begin
        onehot_out = {((1<<BIN_WIDTH)){1'b0}};
        if (enable && adder_sum < (1<<BIN_WIDTH)) begin
            for (i = 0; i < (1<<BIN_WIDTH); i = i + 1) begin
                if (i == adder_sum)
                    onehot_out[i] = 1'b1;
            end
        end
    end
endmodule

module parallel_prefix_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    // Generate and Propagate signals
    wire [3:0] g, p;
    wire [3:0] c;

    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    wire [3:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // Stage 2
    wire [3:0] g2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign g2[3] = g1[3] | (p1[3] & g1[1]);

    // Carry
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1[1] | (p1[1] & cin);
    assign c[3] = g2[2] | (p1[2] & cin);

    // Sum and carry out
    assign sum = p ^ c;
    assign cout = g2[3] | (p1[3] & cin);
endmodule