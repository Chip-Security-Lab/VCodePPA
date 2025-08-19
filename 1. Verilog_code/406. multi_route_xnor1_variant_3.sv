//SystemVerilog
// Top level module
module multi_route_xnor1 (
    input  wire A, B, C,
    output wire Y
);
    wire xnor_ab, xnor_bc, xnor_ac;
    
    // Instantiate XNOR submodules
    xnor_gate xnor_gate_ab (
        .input_a(A),
        .input_b(B),
        .result(xnor_ab)
    );
    
    xnor_gate xnor_gate_bc (
        .input_a(B),
        .input_b(C),
        .result(xnor_bc)
    );
    
    xnor_gate xnor_gate_ac (
        .input_a(A),
        .input_b(C),
        .result(xnor_ac)
    );
    
    // Instantiate AND module to combine results
    and_gate_3input and_gate_final (
        .input_a(xnor_ab),
        .input_b(xnor_bc),
        .input_c(xnor_ac),
        .result(Y)
    );
endmodule

// XNOR submodule
module xnor_gate (
    input  wire input_a, input_b,
    output wire result
);
    assign result = ~(input_a ^ input_b);
endmodule

// 3-input AND submodule
module and_gate_3input (
    input  wire input_a, input_b, input_c,
    output wire result
);
    assign result = input_a & input_b & input_c;
endmodule