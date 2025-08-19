module tristate_demux (
    input wire data,                     // Input data
    input wire [1:0] select,             // Selection control
    input wire output_enable,            // Output enable
    output wire [3:0] demux_bus          // Tristate output bus
);
    // Conditional tristate outputs
    assign demux_bus[0] = (output_enable && select == 2'b00) ? data : 1'bz;
    assign demux_bus[1] = (output_enable && select == 2'b01) ? data : 1'bz;
    assign demux_bus[2] = (output_enable && select == 2'b10) ? data : 1'bz;
    assign demux_bus[3] = (output_enable && select == 2'b11) ? data : 1'bz;
endmodule