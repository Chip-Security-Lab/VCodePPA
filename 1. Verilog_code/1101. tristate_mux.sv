module tristate_mux (
    input wire [7:0] source_a, source_b, // Data sources
    input wire select,            // Selection control
    input wire output_enable,     // Output enable
    output wire [7:0] data_bus    // Tristate output bus
);
    assign data_bus = output_enable ? (select ? source_b : source_a) : 8'bz;
endmodule