//SystemVerilog
module simple_2to1_mux (
    input wire [7:0] data0,         // 8-bit Data input 0
    input wire [7:0] data1,         // 8-bit Data input 1
    input wire sel,                 // Selection signal
    input wire [7:0] mult_a,        // 8-bit multiplier input A
    input wire [7:0] mult_b,        // 8-bit multiplier input B
    output wire [7:0] mux_out,      // 8-bit Output data
    output wire [15:0] mult_out     // 16-bit Multiplier result
);

    reg [7:0] mux_out_reg;

    always @(*) begin
        if (sel) begin
            mux_out_reg = data1;
        end else begin
            mux_out_reg = data0;
        end
    end

    assign mux_out = mux_out_reg;

    wallace_tree_multiplier_8x8 u_wallace_tree_multiplier_8x8 (
        .a(mult_a),
        .b(mult_b),
        .product(mult_out)
    );

endmodule

module wallace_tree_multiplier_8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] product
);
    // Generate partial products
    wire [7:0] pp [7:0];
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : gen_partial_products
            assign pp[i] = a & {8{b[i]}};
        end
    endgenerate

    // First reduction stage
    wire [7:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6;
    wire [7:0] c1_0, c1_1, c1_2, c1_3, c1_4, c1_5, c1_6;

    // Full adders for stage 1
    assign {c1_0[0], s1_0[0]} = {1'b0, pp[0][0]};
    assign {c1_0[1], s1_0[1]} = {1'b0, pp[0][1] ^ pp[1][0]};
    assign {c1_0[2], s1_0[2]} = {1'b0, pp[0][2] ^ pp[1][1] ^ pp[2][0]};
    assign {c1_0[3], s1_0[3]} = {1'b0, pp[0][3] ^ pp[1][2] ^ pp[2][1]};
    assign {c1_0[4], s1_0[4]} = {1'b0, pp[0][4] ^ pp[1][3] ^ pp[2][2]};
    assign {c1_0[5], s1_0[5]} = {1'b0, pp[0][5] ^ pp[1][4] ^ pp[2][3]};
    assign {c1_0[6], s1_0[6]} = {1'b0, pp[0][6] ^ pp[1][5] ^ pp[2][4]};
    assign {c1_0[7], s1_0[7]} = {1'b0, pp[0][7] ^ pp[1][6] ^ pp[2][5]};

    assign {c1_1[0], s1_1[0]} = {1'b0, pp[1][7] ^ pp[2][6] ^ pp[3][5]};
    assign {c1_1[1], s1_1[1]} = {1'b0, pp[2][7] ^ pp[3][6] ^ pp[4][5]};
    assign {c1_1[2], s1_1[2]} = {1'b0, pp[3][7] ^ pp[4][6] ^ pp[5][5]};
    assign {c1_1[3], s1_1[3]} = {1'b0, pp[4][7] ^ pp[5][6] ^ pp[6][5]};
    assign {c1_1[4], s1_1[4]} = {1'b0, pp[5][7] ^ pp[6][6] ^ pp[7][5]};
    assign {c1_1[5], s1_1[5]} = {1'b0, pp[6][7] ^ pp[7][6]};
    assign {c1_1[6], s1_1[6]} = {1'b0, pp[7][7]};
    assign {c1_1[7], s1_1[7]} = {1'b0, 1'b0};

    // Second reduction stage (using carry-save adder approach)
    wire [15:0] sum, carry;

    assign sum[0]  = pp[0][0];
    assign sum[1]  = pp[0][1] ^ pp[1][0];
    assign carry[1] = pp[0][1] & pp[1][0];
    assign sum[2]  = pp[0][2] ^ pp[1][1] ^ pp[2][0];
    assign carry[2] = (pp[0][2] & pp[1][1]) | (pp[0][2] & pp[2][0]) | (pp[1][1] & pp[2][0]);
    assign sum[3]  = pp[0][3] ^ pp[1][2] ^ pp[2][1] ^ pp[3][0];
    assign carry[3] = (pp[0][3] & pp[1][2]) | (pp[0][3] & pp[2][1]) | (pp[0][3] & pp[3][0]) |
                      (pp[1][2] & pp[2][1]) | (pp[1][2] & pp[3][0]) | (pp[2][1] & pp[3][0]);
    assign sum[4]  = pp[0][4] ^ pp[1][3] ^ pp[2][2] ^ pp[3][1] ^ pp[4][0];
    assign carry[4] = (pp[0][4] & pp[1][3]) | (pp[0][4] & pp[2][2]) | (pp[0][4] & pp[3][1]) | (pp[0][4] & pp[4][0]) |
                      (pp[1][3] & pp[2][2]) | (pp[1][3] & pp[3][1]) | (pp[1][3] & pp[4][0]) |
                      (pp[2][2] & pp[3][1]) | (pp[2][2] & pp[4][0]) | (pp[3][1] & pp[4][0]);
    assign sum[5]  = pp[0][5] ^ pp[1][4] ^ pp[2][3] ^ pp[3][2] ^ pp[4][1] ^ pp[5][0];
    assign carry[5] = (pp[0][5] & pp[1][4]) | (pp[0][5] & pp[2][3]) | (pp[0][5] & pp[3][2]) | (pp[0][5] & pp[4][1]) | (pp[0][5] & pp[5][0]) |
                      (pp[1][4] & pp[2][3]) | (pp[1][4] & pp[3][2]) | (pp[1][4] & pp[4][1]) | (pp[1][4] & pp[5][0]) |
                      (pp[2][3] & pp[3][2]) | (pp[2][3] & pp[4][1]) | (pp[2][3] & pp[5][0]) |
                      (pp[3][2] & pp[4][1]) | (pp[3][2] & pp[5][0]) |
                      (pp[4][1] & pp[5][0]);
    assign sum[6]  = pp[0][6] ^ pp[1][5] ^ pp[2][4] ^ pp[3][3] ^ pp[4][2] ^ pp[5][1] ^ pp[6][0];
    assign carry[6] = (pp[0][6] & pp[1][5]) | (pp[0][6] & pp[2][4]) | (pp[0][6] & pp[3][3]) | (pp[0][6] & pp[4][2]) | (pp[0][6] & pp[5][1]) | (pp[0][6] & pp[6][0]) |
                      (pp[1][5] & pp[2][4]) | (pp[1][5] & pp[3][3]) | (pp[1][5] & pp[4][2]) | (pp[1][5] & pp[5][1]) | (pp[1][5] & pp[6][0]) |
                      (pp[2][4] & pp[3][3]) | (pp[2][4] & pp[4][2]) | (pp[2][4] & pp[5][1]) | (pp[2][4] & pp[6][0]) |
                      (pp[3][3] & pp[4][2]) | (pp[3][3] & pp[5][1]) | (pp[3][3] & pp[6][0]) |
                      (pp[4][2] & pp[5][1]) | (pp[4][2] & pp[6][0]) |
                      (pp[5][1] & pp[6][0]);
    assign sum[7]  = pp[0][7] ^ pp[1][6] ^ pp[2][5] ^ pp[3][4] ^ pp[4][3] ^ pp[5][2] ^ pp[6][1] ^ pp[7][0];
    assign carry[7] = (pp[0][7] & pp[1][6]) | (pp[0][7] & pp[2][5]) | (pp[0][7] & pp[3][4]) | (pp[0][7] & pp[4][3]) | (pp[0][7] & pp[5][2]) | (pp[0][7] & pp[6][1]) | (pp[0][7] & pp[7][0]) |
                      (pp[1][6] & pp[2][5]) | (pp[1][6] & pp[3][4]) | (pp[1][6] & pp[4][3]) | (pp[1][6] & pp[5][2]) | (pp[1][6] & pp[6][1]) | (pp[1][6] & pp[7][0]) |
                      (pp[2][5] & pp[3][4]) | (pp[2][5] & pp[4][3]) | (pp[2][5] & pp[5][2]) | (pp[2][5] & pp[6][1]) | (pp[2][5] & pp[7][0]) |
                      (pp[3][4] & pp[4][3]) | (pp[3][4] & pp[5][2]) | (pp[3][4] & pp[6][1]) | (pp[3][4] & pp[7][0]) |
                      (pp[4][3] & pp[5][2]) | (pp[4][3] & pp[6][1]) | (pp[4][3] & pp[7][0]) |
                      (pp[5][2] & pp[6][1]) | (pp[5][2] & pp[7][0]) |
                      (pp[6][1] & pp[7][0]);
    // The rest of the bits
    assign sum[8]  = pp[1][7] ^ pp[2][6] ^ pp[3][5] ^ pp[4][4] ^ pp[5][3] ^ pp[6][2] ^ pp[7][1];
    assign carry[8] = (pp[1][7] & pp[2][6]) | (pp[1][7] & pp[3][5]) | (pp[1][7] & pp[4][4]) | (pp[1][7] & pp[5][3]) | (pp[1][7] & pp[6][2]) | (pp[1][7] & pp[7][1]) |
                      (pp[2][6] & pp[3][5]) | (pp[2][6] & pp[4][4]) | (pp[2][6] & pp[5][3]) | (pp[2][6] & pp[6][2]) | (pp[2][6] & pp[7][1]) |
                      (pp[3][5] & pp[4][4]) | (pp[3][5] & pp[5][3]) | (pp[3][5] & pp[6][2]) | (pp[3][5] & pp[7][1]) |
                      (pp[4][4] & pp[5][3]) | (pp[4][4] & pp[6][2]) | (pp[4][4] & pp[7][1]) |
                      (pp[5][3] & pp[6][2]) | (pp[5][3] & pp[7][1]) |
                      (pp[6][2] & pp[7][1]);
    assign sum[9]  = pp[2][7] ^ pp[3][6] ^ pp[4][5] ^ pp[5][4] ^ pp[6][3] ^ pp[7][2];
    assign carry[9] = (pp[2][7] & pp[3][6]) | (pp[2][7] & pp[4][5]) | (pp[2][7] & pp[5][4]) | (pp[2][7] & pp[6][3]) | (pp[2][7] & pp[7][2]) |
                      (pp[3][6] & pp[4][5]) | (pp[3][6] & pp[5][4]) | (pp[3][6] & pp[6][3]) | (pp[3][6] & pp[7][2]) |
                      (pp[4][5] & pp[5][4]) | (pp[4][5] & pp[6][3]) | (pp[4][5] & pp[7][2]) |
                      (pp[5][4] & pp[6][3]) | (pp[5][4] & pp[7][2]) |
                      (pp[6][3] & pp[7][2]);
    assign sum[10] = pp[3][7] ^ pp[4][6] ^ pp[5][5] ^ pp[6][4] ^ pp[7][3];
    assign carry[10] = (pp[3][7] & pp[4][6]) | (pp[3][7] & pp[5][5]) | (pp[3][7] & pp[6][4]) | (pp[3][7] & pp[7][3]) |
                       (pp[4][6] & pp[5][5]) | (pp[4][6] & pp[6][4]) | (pp[4][6] & pp[7][3]) |
                       (pp[5][5] & pp[6][4]) | (pp[5][5] & pp[7][3]) |
                       (pp[6][4] & pp[7][3]);
    assign sum[11] = pp[4][7] ^ pp[5][6] ^ pp[6][5] ^ pp[7][4];
    assign carry[11] = (pp[4][7] & pp[5][6]) | (pp[4][7] & pp[6][5]) | (pp[4][7] & pp[7][4]) |
                       (pp[5][6] & pp[6][5]) | (pp[5][6] & pp[7][4]) |
                       (pp[6][5] & pp[7][4]);
    assign sum[12] = pp[5][7] ^ pp[6][6] ^ pp[7][5];
    assign carry[12] = (pp[5][7] & pp[6][6]) | (pp[5][7] & pp[7][5]) |
                       (pp[6][6] & pp[7][5]);
    assign sum[13] = pp[6][7] ^ pp[7][6];
    assign carry[13] = pp[6][7] & pp[7][6];
    assign sum[14] = pp[7][7];
    assign carry[14] = 1'b0;
    assign sum[15] = 1'b0;
    assign carry[15] = 1'b0;

    // Final addition (carry propagate adder)
    assign product = sum + (carry << 1);

endmodule