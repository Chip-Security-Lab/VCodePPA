//SystemVerilog
// Top-level module: Hierarchical parity generator
module parity_gen #(parameter TYPE=0) (
    input  [7:0] data,
    output       parity
);

    wire data_parity;

    // Submodule: Computes the XOR reduction of input data bits
    data_parity_calc u_data_parity_calc (
        .data_in    (data),
        .parity_out (data_parity)
    );

    // Submodule: Adjusts parity based on TYPE (even/odd)
    parity_type_adjust #(.TYPE(TYPE)) u_parity_type_adjust (
        .raw_parity (data_parity),
        .adj_parity (parity)
    );

endmodule

// Submodule: data_parity_calc
// Calculates the XOR reduction (parity) of the 8-bit input data
module data_parity_calc (
    input  [7:0] data_in,
    output       parity_out
);
    // Simplified XOR reduction using balanced tree structure for minimal logic depth
    wire t0, t1, t2, t3;
    assign t0 = data_in[0] ^ data_in[1];
    assign t1 = data_in[2] ^ data_in[3];
    assign t2 = data_in[4] ^ data_in[5];
    assign t3 = data_in[6] ^ data_in[7];
    assign parity_out = (t0 ^ t1) ^ (t2 ^ t3);
endmodule

// Submodule: parity_type_adjust
// Adjusts the calculated parity based on the TYPE parameter (0: even, 1: odd)
module parity_type_adjust #(parameter TYPE=0) (
    input  raw_parity,
    output adj_parity
);
    // Simplified using Boolean algebra: XOR is already minimal for this adjustment
    assign adj_parity = raw_parity ^ TYPE;
endmodule