module simple_2to1_mux (
    input wire data0, data1,      // Data inputs
    input wire sel,               // Selection signal
    output wire mux_out           // Output data
);
    // Combinational logic using conditional operator
    assign mux_out = sel ? data1 : data0;
endmodule