//SystemVerilog
// 8-input AND gate with hierarchical implementation
module and_gate_8input (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    input wire d,  // Input D
    input wire e,  // Input E
    input wire f,  // Input F
    input wire g,  // Input G
    input wire h,  // Input H
    output wire y  // Output Y
);
    // Intermediate signals for balanced tree structure
    wire ab, cd, ef, gh;
    wire abcd, efgh;
    
    // First level - 2-input AND gates
    assign ab = a & b;
    assign cd = c & d;
    assign ef = e & f;
    assign gh = g & h;
    
    // Second level - 2-input AND gates
    assign abcd = ab & cd;
    assign efgh = ef & gh;
    
    // Final level - 2-input AND gate
    assign y = abcd & efgh;
endmodule