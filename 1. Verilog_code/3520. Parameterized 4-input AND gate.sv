// Parameterized 4-input AND gate with adjustable width
module and_gate_4param #(parameter WIDTH = 4) (
    input wire [WIDTH-1:0] a,  // Input A
    input wire [WIDTH-1:0] b,  // Input B
    input wire [WIDTH-1:0] c,  // Input C
    input wire [WIDTH-1:0] d,  // Input D
    output wire [WIDTH-1:0] y  // Output Y
);
    assign y = a & b & c & d;  // AND operation
endmodule
