//SystemVerilog
module dual_rail_encoder #(parameter WIDTH = 4) (
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire [2*WIDTH-1:0] dual_rail_out
);
    wire [WIDTH-1:0] adder_a;
    wire [WIDTH-1:0] adder_b;
    wire [WIDTH:0]   adder_sum;

    // Example usage: adder_a and adder_b can be connected as needed
    assign adder_a = data_in;
    assign adder_b = {WIDTH{1'b1}}; // Example: add all ones, replace as required

    han_carlson_adder_8bit u_han_carlson_adder_8bit (
        .a      (adder_a),
        .b      (adder_b),
        .cin    (1'b0),
        .sum    (adder_sum[WIDTH-1:0]),
        .cout   (adder_sum[WIDTH])
    );

    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_dual_rail
            assign dual_rail_out[2*i]   = valid_in & data_in[i];
            assign dual_rail_out[2*i+1] = valid_in & ~data_in[i];
        end
    endgenerate
endmodule

module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] g, p;
    wire [7:0] g_stage1, p_stage1;
    wire [7:0] g_stage2, p_stage2;
    wire [7:0] g_stage3, p_stage3;
    wire [7:0] g_stage4, p_stage4;
    wire [7:0] carry;

    // Preprocessing
    assign g = a & b;
    assign p = a ^ b;

    // Stage 1: 1-bit
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    assign p_stage1[3] = p[3] & p[2];
    assign g_stage1[4] = g[4] | (p[4] & g[3]);
    assign p_stage1[4] = p[4] & p[3];
    assign g_stage1[5] = g[5] | (p[5] & g[4]);
    assign p_stage1[5] = p[5] & p[4];
    assign g_stage1[6] = g[6] | (p[6] & g[5]);
    assign p_stage1[6] = p[6] & p[5];
    assign g_stage1[7] = g[7] | (p[7] & g[6]);
    assign p_stage1[7] = p[7] & p[6];

    // Stage 2: 2-bit
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[4] = g_stage1[4] | (p_stage1[4] & g_stage1[2]);
    assign p_stage2[4] = p_stage1[4] & p_stage1[2];
    assign g_stage2[5] = g_stage1[5] | (p_stage1[5] & g_stage1[3]);
    assign p_stage2[5] = p_stage1[5] & p_stage1[3];
    assign g_stage2[6] = g_stage1[6] | (p_stage1[6] & g_stage1[4]);
    assign p_stage2[6] = p_stage1[6] & p_stage1[4];
    assign g_stage2[7] = g_stage1[7] | (p_stage1[7] & g_stage1[5]);
    assign p_stage2[7] = p_stage1[7] & p_stage1[5];

    // Stage 3: 4-bit
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[3] = g_stage2[3];
    assign p_stage3[3] = p_stage2[3];
    assign g_stage3[4] = g_stage2[4] | (p_stage2[4] & g_stage2[0]);
    assign p_stage3[4] = p_stage2[4] & p_stage2[0];
    assign g_stage3[5] = g_stage2[5] | (p_stage2[5] & g_stage2[1]);
    assign p_stage3[5] = p_stage2[5] & p_stage2[1];
    assign g_stage3[6] = g_stage2[6] | (p_stage2[6] & g_stage2[2]);
    assign p_stage3[6] = p_stage2[6] & p_stage2[2];
    assign g_stage3[7] = g_stage2[7] | (p_stage2[7] & g_stage2[3]);
    assign p_stage3[7] = p_stage2[7] & p_stage2[3];

    // Stage 4: 8-bit
    assign g_stage4[0] = g_stage3[0];
    assign p_stage4[0] = p_stage3[0];
    assign g_stage4[1] = g_stage3[1];
    assign p_stage4[1] = p_stage3[1];
    assign g_stage4[2] = g_stage3[2];
    assign p_stage4[2] = p_stage3[2];
    assign g_stage4[3] = g_stage3[3];
    assign p_stage4[3] = p_stage3[3];
    assign g_stage4[4] = g_stage3[4];
    assign p_stage4[4] = p_stage3[4];
    assign g_stage4[5] = g_stage3[5];
    assign p_stage4[5] = p_stage3[5];
    assign g_stage4[6] = g_stage3[6];
    assign p_stage4[6] = p_stage3[6];
    assign g_stage4[7] = g_stage3[7] | (p_stage3[7] & g_stage3[3]);
    assign p_stage4[7] = p_stage3[7] & p_stage3[3];

    // Carry calculation
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & cin);
    assign carry[2] = g_stage1[1] | (p_stage1[1] & cin);
    assign carry[3] = g_stage2[2] | (p_stage2[2] & cin);
    assign carry[4] = g_stage3[3] | (p_stage3[3] & cin);
    assign carry[5] = g_stage4[4] | (p_stage4[4] & cin);
    assign carry[6] = g_stage4[5] | (p_stage4[5] & cin);
    assign carry[7] = g_stage4[6] | (p_stage4[6] & cin);
    assign cout     = g_stage4[7] | (p_stage4[7] & cin);

    // Sum calculation
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    assign sum[4] = p[4] ^ carry[4];
    assign sum[5] = p[5] ^ carry[5];
    assign sum[6] = p[6] ^ carry[6];
    assign sum[7] = p[7] ^ carry[7];
endmodule