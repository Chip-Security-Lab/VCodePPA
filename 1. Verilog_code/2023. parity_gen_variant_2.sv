//SystemVerilog
// Top-level Parity Generator Module (Hierarchical Structure)
module parity_gen #(parameter TYPE=0) ( // 0: Even, 1: Odd
    input  [7:0] data,
    output       parity
);

    wire parity_bit;

    // Submodule: Calculates the basic parity (XOR of all data bits)
    parity_calc u_parity_calc (
        .data_in(data),
        .parity_out(parity_bit)
    );

    // Submodule: Adjusts parity for Even/Odd selection
    parity_type_sel #(.TYPE(TYPE)) u_parity_type_sel (
        .parity_in(parity_bit),
        .parity_out(parity)
    );

endmodule

// -----------------------------------------------------------------------------
// Parity Calculation Submodule
// Calculates the XOR of all data bits (basic parity)
// -----------------------------------------------------------------------------
module parity_calc (
    input  [7:0] data_in,
    output       parity_out
);
    assign parity_out = ^data_in;
endmodule

// -----------------------------------------------------------------------------
// Parity Type Selection Submodule
// Adjusts the parity bit for Even/Odd selection using the TYPE parameter
// TYPE=0: Even parity, TYPE=1: Odd parity
// -----------------------------------------------------------------------------
module parity_type_sel #(parameter TYPE=0) (
    input  parity_in,
    output parity_out
);
    assign parity_out = parity_in ^ TYPE;
endmodule