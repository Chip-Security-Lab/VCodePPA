//SystemVerilog
// Top-level module
module xor_iterative(
    input [3:0] x,
    input [3:0] y,
    output [3:0] z
);
    wire [3:0] propagate_signals;
    
    // Instantiate the propagate signal generator
    propagate_generator pg_inst (
        .x_in(x),
        .y_in(y),
        .p_out(propagate_signals)
    );
    
    // Instantiate the output stage
    output_stage os_inst (
        .p_in(propagate_signals),
        .z_out(z)
    );
endmodule

// Propagate signal generator module
module propagate_generator(
    input [3:0] x_in,
    input [3:0] y_in,
    output [3:0] p_out
);
    // Generate propagate signals
    assign p_out = x_in ^ y_in;
endmodule

// Output stage module
module output_stage(
    input [3:0] p_in,
    output [3:0] z_out
);
    // For XOR operation, the result is directly the propagate signals
    assign z_out = p_in;
endmodule