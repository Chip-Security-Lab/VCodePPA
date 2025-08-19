//SystemVerilog
// Top-level module: 4-input AND gate (4-bit wide)
module and_gate_4bit (
    input wire [3:0] a,  // 4-bit input A
    input wire [3:0] b,  // 4-bit input B
    input wire [3:0] c,  // 4-bit input C
    input wire [3:0] d,  // 4-bit input D
    output wire [3:0] y  // 4-bit output Y
);
    // Intermediate signals
    wire [3:0] ab_result;
    wire [3:0] cd_result;
    
    // Instantiate first-level AND operation (A & B)
    and_gate_2input #(.WIDTH(4)) and_ab (
        .in1(a),
        .in2(b),
        .out(ab_result)
    );
    
    // Instantiate first-level AND operation (C & D)
    and_gate_2input #(.WIDTH(4)) and_cd (
        .in1(c),
        .in2(d),
        .out(cd_result)
    );
    
    // Instantiate second-level AND operation (AB & CD)
    and_gate_2input #(.WIDTH(4)) and_final (
        .in1(ab_result),
        .in2(cd_result),
        .out(y)
    );
endmodule

// Parameterized 2-input AND gate module
module and_gate_2input #(
    parameter WIDTH = 4  // Default width is 4 bits
)(
    input wire [WIDTH-1:0] in1,   // First input
    input wire [WIDTH-1:0] in2,   // Second input
    output wire [WIDTH-1:0] out   // Output result
);
    // Simple 2-input AND operation
    assign out = in1 & in2;
endmodule