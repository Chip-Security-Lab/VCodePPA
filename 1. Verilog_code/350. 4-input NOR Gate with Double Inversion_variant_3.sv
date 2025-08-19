//SystemVerilog
// Top-level module: nor4_double_invert
module nor4_double_invert (
    input  wire A, 
    input  wire B, 
    input  wire C, 
    input  wire D,
    output wire Y
);
    wire nor_logic_result;

    // Optimized 4-input NOR logic
    nor4_logic u_nor4_logic (
        .in_a(A),
        .in_b(B),
        .in_c(C),
        .in_d(D),
        .nor_out(nor_logic_result)
    );

    // Output buffer for future PPA tuning
    output_buffer u_output_buffer (
        .in_signal(nor_logic_result),
        .out_signal(Y)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: nor4_logic
// Function: Performs a 4-input NOR logic operation (optimized Boolean expression)
// -----------------------------------------------------------------------------
module nor4_logic (
    input  wire in_a,
    input  wire in_b,
    input  wire in_c,
    input  wire in_d,
    output wire nor_out
);
    // Simplified using DeMorgan's Law: ~(a|b|c|d) = ~a & ~b & ~c & ~d
    assign nor_out = (~in_a) & (~in_b) & (~in_c) & (~in_d);
endmodule

// -----------------------------------------------------------------------------
// Submodule: output_buffer
// Function: Buffers the input signal to output, allows for future PPA tuning
// -----------------------------------------------------------------------------
module output_buffer (
    input  wire in_signal,
    output wire out_signal
);
    assign out_signal = in_signal;
endmodule