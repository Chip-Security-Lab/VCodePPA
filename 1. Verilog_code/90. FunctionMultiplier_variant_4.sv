//SystemVerilog
module FunctionMultiplier(
    input [3:0] m, n,
    output [7:0] res
);

    // Partial products generation
    wire [3:0][3:0] pp;
    
    // Unrolled partial product generation
    assign pp[0][0] = m[0] & n[0];
    assign pp[0][1] = m[0] & n[1];
    assign pp[0][2] = m[0] & n[2];
    assign pp[0][3] = m[0] & n[3];
    
    assign pp[1][0] = m[1] & n[0];
    assign pp[1][1] = m[1] & n[1];
    assign pp[1][2] = m[1] & n[2];
    assign pp[1][3] = m[1] & n[3];
    
    assign pp[2][0] = m[2] & n[0];
    assign pp[2][1] = m[2] & n[1];
    assign pp[2][2] = m[2] & n[2];
    assign pp[2][3] = m[2] & n[3];
    
    assign pp[3][0] = m[3] & n[0];
    assign pp[3][1] = m[3] & n[1];
    assign pp[3][2] = m[3] & n[2];
    assign pp[3][3] = m[3] & n[3];

    // Dadda tree reduction with carry-save adder
    wire [7:0] sum, carry;
    wire [3:0] s1, c1;
    wire [4:0] s2, c2;
    wire [5:0] s3, c3;
    wire [6:0] s4, c4;

    // Stage 1: Carry-save adders
    assign {c1[0], s1[0]} = pp[0][0] + pp[0][1] + pp[1][0];
    assign {c1[1], s1[1]} = pp[0][2] + pp[1][1] + pp[2][0];
    assign {c1[2], s1[2]} = pp[0][3] + pp[1][2] + pp[2][1] + pp[3][0];
    assign {c1[3], s1[3]} = pp[1][3] + pp[2][2] + pp[3][1];

    // Stage 2: Carry-save adders
    assign {c2[0], s2[0]} = s1[0] + c1[0] + pp[1][1];
    assign {c2[1], s2[1]} = s1[1] + c1[1] + pp[2][1];
    assign {c2[2], s2[2]} = s1[2] + c1[2] + pp[3][2];
    assign {c2[3], s2[3]} = s1[3] + c1[3] + pp[2][3];
    assign {c2[4], s2[4]} = pp[3][3];

    // Stage 3: Carry-save adders
    assign {c3[0], s3[0]} = s2[0] + c2[0] + pp[2][0];
    assign {c3[1], s3[1]} = s2[1] + c2[1] + pp[3][1];
    assign {c3[2], s3[2]} = s2[2] + c2[2] + pp[3][2];
    assign {c3[3], s3[3]} = s2[3] + c2[3] + pp[3][3];
    assign {c3[4], s3[4]} = s2[4] + c2[4];
    assign {c3[5], s3[5]} = pp[3][3];

    // Stage 4: Carry-save adder with ripple carry
    wire [6:0] carry_chain;
    assign {carry_chain[0], s4[0]} = s3[0] + c3[0];
    assign {carry_chain[1], s4[1]} = s3[1] + c3[1] + carry_chain[0];
    assign {carry_chain[2], s4[2]} = s3[2] + c3[2] + carry_chain[1];
    assign {carry_chain[3], s4[3]} = s3[3] + c3[3] + carry_chain[2];
    assign {carry_chain[4], s4[4]} = s3[4] + c3[4] + carry_chain[3];
    assign {carry_chain[5], s4[5]} = s3[5] + c3[5] + carry_chain[4];
    assign s4[6] = carry_chain[5];

    // Final result
    assign res = {s4[6:0], pp[0][0]};

endmodule