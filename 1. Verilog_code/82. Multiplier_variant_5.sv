//SystemVerilog
// Top level multiplier module
module Multiplier2#(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);

    // Partial products generation
    wire [WIDTH-1:0] pp [WIDTH-1:0];
    PartialProductGen #(.WIDTH(WIDTH)) pp_gen (
        .x(x),
        .y(y),
        .pp(pp)
    );

    // Wallace tree reduction
    wire [2*WIDTH-1:0] sum, carry;
    WallaceTree #(.WIDTH(WIDTH)) wallace_tree (
        .pp(pp),
        .sum(sum),
        .carry(carry)
    );

    // Final addition
    assign product = sum + (carry << 1);

endmodule

// Partial product generation module
module PartialProductGen #(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [WIDTH-1:0] pp [WIDTH-1:0]
);

    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: pp_gen
            for (j = 0; j < WIDTH; j = j + 1) begin: pp_row
                assign pp[i][j] = x[j] & y[i];
            end
        end
    endgenerate

endmodule

// Wallace tree reduction module
module WallaceTree #(parameter WIDTH=4)(
    input [WIDTH-1:0] pp [WIDTH-1:0],
    output [2*WIDTH-1:0] sum,
    output [2*WIDTH-1:0] carry
);

    // Stage 1: Generate half adders and full adders
    wire [2*WIDTH-1:0] stage1_sum, stage1_carry;
    Stage1Reduction #(.WIDTH(WIDTH)) stage1 (
        .pp(pp),
        .sum(stage1_sum),
        .carry(stage1_carry)
    );

    // Stage 2: Continue reduction
    wire [2*WIDTH-1:0] stage2_sum, stage2_carry;
    Stage2Reduction #(.WIDTH(WIDTH)) stage2 (
        .stage1_sum(stage1_sum),
        .stage1_carry(stage1_carry),
        .pp(pp),
        .sum(stage2_sum),
        .carry(stage2_carry)
    );

    // Final stage
    assign sum = stage2_sum;
    assign carry = stage2_carry;

endmodule

// Stage 1 reduction module
module Stage1Reduction #(parameter WIDTH=4)(
    input [WIDTH-1:0] pp [WIDTH-1:0],
    output [2*WIDTH-1:0] sum,
    output [2*WIDTH-1:0] carry
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: stage1
            if (i == 0) begin
                assign sum[i] = pp[0][i];
                assign carry[i] = 1'b0;
            end else begin
                assign {carry[i], sum[i]} = pp[0][i] + pp[1][i];
            end
        end
    endgenerate

endmodule

// Stage 2 reduction module
module Stage2Reduction #(parameter WIDTH=4)(
    input [2*WIDTH-1:0] stage1_sum,
    input [2*WIDTH-1:0] stage1_carry,
    input [WIDTH-1:0] pp [WIDTH-1:0],
    output [2*WIDTH-1:0] sum,
    output [2*WIDTH-1:0] carry
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: stage2
            if (i < WIDTH-2) begin
                assign {carry[i], sum[i]} = stage1_sum[i] + stage1_carry[i] + pp[2][i];
            end else begin
                assign sum[i] = stage1_sum[i];
                assign carry[i] = stage1_carry[i];
            end
        end
    endgenerate

endmodule