//SystemVerilog
// Top-level module
module SignedMultiplier(
    input signed [7:0] a, b,
    output signed [15:0] result
);

    // Partial products generation
    wire [7:0] pp[7:0];
    PartialProductGenerator pp_gen(
        .a(a),
        .b(b),
        .pp(pp)
    );

    // Dadda tree reduction
    wire [15:0] stage1_sum, stage1_carry;
    wire [15:0] stage2_sum, stage2_carry;

    DaddaStage1 dadda1(
        .pp(pp),
        .sum(stage1_sum),
        .carry(stage1_carry)
    );

    DaddaStage2 dadda2(
        .sum_in(stage1_sum),
        .carry_in(stage1_carry),
        .sum(stage2_sum),
        .carry(stage2_carry)
    );

    // Final addition
    assign result = stage2_sum + stage2_carry;

endmodule

// Partial product generation module
module PartialProductGenerator(
    input signed [7:0] a,
    input signed [7:0] b,
    output [7:0] pp[7:0]
);

    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin : gen_pp
            assign pp[i] = a & {8{b[i]}};
        end
    endgenerate

endmodule

// First stage of Dadda tree
module DaddaStage1(
    input [7:0] pp[7:0],
    output [15:0] sum,
    output [15:0] carry
);

    // Column reduction modules
    ColumnReducer col0(
        .pp(pp),
        .col_idx(0),
        .sum(sum[0]),
        .carry(carry[0])
    );

    ColumnReducer col1(
        .pp(pp),
        .col_idx(1),
        .sum(sum[1]),
        .carry(carry[1])
    );

    ColumnReducer col2(
        .pp(pp),
        .col_idx(2),
        .sum(sum[2]),
        .carry(carry[2])
    );

    genvar i;
    generate
        for(i = 3; i < 16; i = i + 1) begin : gen_stage1
            ColumnReducer col(
                .pp(pp),
                .col_idx(i),
                .sum(sum[i]),
                .carry(carry[i])
            );
        end
    endgenerate

endmodule

// Column reduction module
module ColumnReducer(
    input [7:0] pp[7:0],
    input [3:0] col_idx,
    output sum,
    output carry
);

    wire [7:0] col_bits;
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin : gen_col
            assign col_bits[i] = (col_idx >= i) ? pp[i][col_idx-i] : 1'b0;
        end
    endgenerate

    assign sum = ^col_bits;
    assign carry = |(col_bits & {col_bits[6:0], 1'b0});

endmodule

// Second stage of Dadda tree
module DaddaStage2(
    input [15:0] sum_in,
    input [15:0] carry_in,
    output [15:0] sum,
    output [15:0] carry
);

    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : gen_stage2
            FullAdder fa(
                .a(sum_in[i]),
                .b(carry_in[i-1]),
                .cin(1'b0),
                .sum(sum[i]),
                .cout(carry[i])
            );
        end
    endgenerate

endmodule

// Full adder module
module FullAdder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule