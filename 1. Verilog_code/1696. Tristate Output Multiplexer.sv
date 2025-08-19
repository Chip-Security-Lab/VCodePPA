module tristate_mux(
    input [15:0] input_bus_a, input_bus_b,
    input select, output_enable,
    output [15:0] muxed_bus
);
    assign muxed_bus = output_enable ? (select ? input_bus_b : input_bus_a) : 16'bz;
endmodule