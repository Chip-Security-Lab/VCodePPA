//SystemVerilog
module dadda_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Partial products generation
    wire [7:0][7:0] pp;
    
    // Unrolled partial product generation
    assign pp[0][0] = a[0] & b[0];
    assign pp[0][1] = a[0] & b[1];
    assign pp[0][2] = a[0] & b[2];
    assign pp[0][3] = a[0] & b[3];
    assign pp[0][4] = a[0] & b[4];
    assign pp[0][5] = a[0] & b[5];
    assign pp[0][6] = a[0] & b[6];
    assign pp[0][7] = a[0] & b[7];

    assign pp[1][0] = a[1] & b[0];
    assign pp[1][1] = a[1] & b[1];
    assign pp[1][2] = a[1] & b[2];
    assign pp[1][3] = a[1] & b[3];
    assign pp[1][4] = a[1] & b[4];
    assign pp[1][5] = a[1] & b[5];
    assign pp[1][6] = a[1] & b[6];
    assign pp[1][7] = a[1] & b[7];

    assign pp[2][0] = a[2] & b[0];
    assign pp[2][1] = a[2] & b[1];
    assign pp[2][2] = a[2] & b[2];
    assign pp[2][3] = a[2] & b[3];
    assign pp[2][4] = a[2] & b[4];
    assign pp[2][5] = a[2] & b[5];
    assign pp[2][6] = a[2] & b[6];
    assign pp[2][7] = a[2] & b[7];

    assign pp[3][0] = a[3] & b[0];
    assign pp[3][1] = a[3] & b[1];
    assign pp[3][2] = a[3] & b[2];
    assign pp[3][3] = a[3] & b[3];
    assign pp[3][4] = a[3] & b[4];
    assign pp[3][5] = a[3] & b[5];
    assign pp[3][6] = a[3] & b[6];
    assign pp[3][7] = a[3] & b[7];

    assign pp[4][0] = a[4] & b[0];
    assign pp[4][1] = a[4] & b[1];
    assign pp[4][2] = a[4] & b[2];
    assign pp[4][3] = a[4] & b[3];
    assign pp[4][4] = a[4] & b[4];
    assign pp[4][5] = a[4] & b[5];
    assign pp[4][6] = a[4] & b[6];
    assign pp[4][7] = a[4] & b[7];

    assign pp[5][0] = a[5] & b[0];
    assign pp[5][1] = a[5] & b[1];
    assign pp[5][2] = a[5] & b[2];
    assign pp[5][3] = a[5] & b[3];
    assign pp[5][4] = a[5] & b[4];
    assign pp[5][5] = a[5] & b[5];
    assign pp[5][6] = a[5] & b[6];
    assign pp[5][7] = a[5] & b[7];

    assign pp[6][0] = a[6] & b[0];
    assign pp[6][1] = a[6] & b[1];
    assign pp[6][2] = a[6] & b[2];
    assign pp[6][3] = a[6] & b[3];
    assign pp[6][4] = a[6] & b[4];
    assign pp[6][5] = a[6] & b[5];
    assign pp[6][6] = a[6] & b[6];
    assign pp[6][7] = a[6] & b[7];

    assign pp[7][0] = a[7] & b[0];
    assign pp[7][1] = a[7] & b[1];
    assign pp[7][2] = a[7] & b[2];
    assign pp[7][3] = a[7] & b[3];
    assign pp[7][4] = a[7] & b[4];
    assign pp[7][5] = a[7] & b[5];
    assign pp[7][6] = a[7] & b[6];
    assign pp[7][7] = a[7] & b[7];

    // Stage 1: 8x8 to 6x8
    wire [5:0][7:0] stage1;
    assign stage1[0] = pp[0];
    assign stage1[1] = pp[1];
    assign stage1[2] = pp[2];
    assign stage1[3] = pp[3];
    assign stage1[4] = pp[4];
    assign stage1[5] = pp[5];

    // Stage 2: 6x8 to 4x8
    wire [3:0][7:0] stage2;
    assign stage2[0] = stage1[0];
    assign stage2[1] = stage1[1];
    assign stage2[2] = stage1[2];
    assign stage2[3] = stage1[3];

    // Stage 3: 4x8 to 3x8
    wire [2:0][7:0] stage3;
    assign stage3[0] = stage2[0];
    assign stage3[1] = stage2[1];
    assign stage3[2] = stage2[2];

    // Stage 4: 3x8 to 2x8
    wire [1:0][7:0] stage4;
    assign stage4[0] = stage3[0];
    assign stage4[1] = stage3[1];

    // Final addition
    wire [7:0] sum, carry;
    assign {carry, sum} = stage4[0] + stage4[1];

    // Output assignment
    assign product = {carry, sum};

endmodule