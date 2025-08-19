//SystemVerilog
// Top-level module for even parity generation
module even_parity_gen(
    input [7:0] data_in,
    output parity_out
);
    // Internal signals
    wire parity_signal;
    
    // Instantiate the parity calculator submodule
    parity_calculator u_parity_calculator (
        .data(data_in),
        .parity(parity_signal)
    );

    // Output assignment
    assign parity_out = parity_signal;

endmodule

// Submodule for calculating parity
module parity_calculator(
    input [7:0] data,
    output parity
);
    // Calculate even parity using XOR reduction
    assign parity = ^data;

endmodule