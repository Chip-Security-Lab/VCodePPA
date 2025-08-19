//SystemVerilog
module nibble_parity (
    input [3:0] nibble,
    output parity
);
    assign parity = ^nibble;
endmodule

module nibble_combiner (
    input [1:0] nib_par,
    output parity
);
    assign parity = ^nib_par;
endmodule

module cascade_parity (
    input [7:0] data,
    output parity
);
    wire [1:0] nib_par;
    
    nibble_parity nib0 (
        .nibble(data[3:0]),
        .parity(nib_par[0])
    );
    
    nibble_parity nib1 (
        .nibble(data[7:4]),
        .parity(nib_par[1])
    );
    
    nibble_combiner comb (
        .nib_par(nib_par),
        .parity(parity)
    );
endmodule