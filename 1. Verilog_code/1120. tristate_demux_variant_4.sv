//SystemVerilog
// Top-level module: tristate_demux_hier
module tristate_demux_hier (
    input  wire        data_in,          // Serial data input
    input  wire [1:0]  select,           // Output channel select
    input  wire        output_enable,    // Enable for demux operation
    output wire [3:0]  demux_bus         // Tristate data bus
);

    // Internal signals
    wire [3:0] enable_onehot;

    // Channel selection logic submodule
    demux_channel_selector u_channel_selector (
        .sel            (select),
        .enable_global  (output_enable),
        .enable_lines   (enable_onehot)
    );

    // Tristate output driver submodule
    demux_tristate_driver u_tristate_driver (
        .data_in        (data_in),
        .enable_lines   (enable_onehot),
        .bus_out        (demux_bus)
    );

endmodule

// -----------------------------------------------------------------------------
// demux_channel_selector: Decodes select and global enable to generate a
// one-hot per-channel enable signal vector.
// -----------------------------------------------------------------------------
module demux_channel_selector (
    input  wire [1:0] sel,               // 2-bit channel select
    input  wire       enable_global,      // Global output enable
    output wire [3:0] enable_lines        // One-hot enables for each output
);
    // One-hot enable generation
    assign enable_lines[0] = enable_global && (sel == 2'b00);
    assign enable_lines[1] = enable_global && (sel == 2'b01);
    assign enable_lines[2] = enable_global && (sel == 2'b10);
    assign enable_lines[3] = enable_global && (sel == 2'b11);
endmodule

// -----------------------------------------------------------------------------
// demux_tristate_driver: Drives the 4-bit tristate output bus. Each bit is
// driven by data_in if the corresponding enable_lines bit is asserted.
// Otherwise, the output is high-impedance ('z').
// -----------------------------------------------------------------------------
module demux_tristate_driver (
    input  wire        data_in,           // Data to drive onto bus
    input  wire [3:0]  enable_lines,      // Per-channel enables
    output wire [3:0]  bus_out            // Tristate bus
);
    assign bus_out[0] = enable_lines[0] ? data_in : 1'bz;
    assign bus_out[1] = enable_lines[1] ? data_in : 1'bz;
    assign bus_out[2] = enable_lines[2] ? data_in : 1'bz;
    assign bus_out[3] = enable_lines[3] ? data_in : 1'bz;
endmodule