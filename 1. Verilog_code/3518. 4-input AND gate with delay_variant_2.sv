//SystemVerilog
// Top level module - 4-input AND gate with optimized implementation
module and_gate_4_delay (
    input  wire a,  // Input A
    input  wire b,  // Input B
    input  wire c,  // Input C
    input  wire d,  // Input D
    output wire y   // Output Y
);
    // Direct AND operation with delay in single module
    and_gate_4_optimized u_and_final (
        .in1(a),
        .in2(b),
        .in3(c),
        .in4(d),
        .out(y)
    );
endmodule

// Optimized 4-input AND gate with delay
module and_gate_4_optimized (
    input  wire in1,  // First input
    input  wire in2,  // Second input
    input  wire in3,  // Third input
    input  wire in4,  // Fourth input
    output reg  out   // Output with delay
);
    // Single AND operation reduces logic depth and improves timing
    always @(in1, in2, in3, in4) begin
        #3 out = in1 & in2 & in3 & in4;  // 4-input AND with 3-time unit delay
    end
endmodule