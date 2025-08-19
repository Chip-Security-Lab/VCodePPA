//SystemVerilog
// Top-level module: Hierarchical 4-bit 4-input NAND Gate
module nand4_4 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire [3:0] C,
    input  wire [3:0] D,
    output wire [3:0] Y
);

    // Internal wires for inverted inputs
    wire [3:0] A_n;
    wire [3:0] B_n;
    wire [3:0] C_n;
    wire [3:0] D_n;

    // Invert each input vector
    inverter_4bit u_inverter_a (
        .in_vec(A),
        .out_vec(A_n)
    );
    inverter_4bit u_inverter_b (
        .in_vec(B),
        .out_vec(B_n)
    );
    inverter_4bit u_inverter_c (
        .in_vec(C),
        .out_vec(C_n)
    );
    inverter_4bit u_inverter_d (
        .in_vec(D),
        .out_vec(D_n)
    );

    // 4-input OR gate for each bit position
    or4_4bit u_or4_4bit (
        .in0(A_n),
        .in1(B_n),
        .in2(C_n),
        .in3(D_n),
        .out(Y)
    );

endmodule

// 4-bit inverter module
// Purpose: Inverts a 4-bit input vector
module inverter_4bit (
    input  wire [3:0] in_vec,
    output wire [3:0] out_vec
);
    assign out_vec = ~in_vec;
endmodule

// 4-bit 4-input OR gate module
// Purpose: Performs bitwise 4-input OR operation across four 4-bit vectors
module or4_4bit (
    input  wire [3:0] in0,
    input  wire [3:0] in1,
    input  wire [3:0] in2,
    input  wire [3:0] in3,
    output wire [3:0] out
);
    assign out = in0 | in1 | in2 | in3;
endmodule