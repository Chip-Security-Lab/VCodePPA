//SystemVerilog
// Top-level module
module xor_hybrid(
    input  wire a,
    input  wire b,
    output wire y
);
    // 直接使用XOR运算符实现异或功能，简化逻辑深度
    assign y = a ^ b;
endmodule

// Common NAND gate sub-module
module nand_gate(
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = ~(in1 & in2);
endmodule

// Input stage NAND operations
module input_nand_stage(
    input  wire a,
    input  wire b,
    input  wire nand_common,
    output wire a_nand_out,
    output wire b_nand_out
);
    nand_gate nand_a (
        .in1(a),
        .in2(nand_common),
        .out(a_nand_out)
    );

    nand_gate nand_b (
        .in1(b),
        .in2(nand_common),
        .out(b_nand_out)
    );
endmodule

// Output stage NAND operation
module output_nand_stage(
    input  wire in1,
    input  wire in2,
    output wire out
);
    nand_gate final_nand (
        .in1(in1),
        .in2(in2),
        .out(out)
    );
endmodule