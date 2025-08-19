module tristate_buffer (
    input wire [15:0] data_in,
    input wire oe,  // Output enable
    output wire [15:0] data_out
);
    assign data_out = oe ? data_in : 16'bz;
endmodule