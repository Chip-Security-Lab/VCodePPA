//SystemVerilog
// Top-level module: Hierarchical tristate demux

module tristate_demux (
    input wire data,                     // Input data
    input wire [1:0] select,             // Selection control
    input wire output_enable,            // Output enable
    output wire [3:0] demux_bus          // Tristate output bus
);

    wire [3:0] enable_signals;

    // Enable Decoder: Generates individual enable signals based on select and output_enable
    tristate_demux_enable_decoder u_enable_decoder (
        .select_in(select),
        .output_enable_in(output_enable),
        .enable_out(enable_signals)
    );

    // Tristate Buffer Array: Drives demux_bus with data under control of enable_signals
    tristate_demux_tristate_buffer_array u_tristate_buffer_array (
        .data_in(data),
        .enable_in(enable_signals),
        .bus_out(demux_bus)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: Enable Decoder
// Description: Decodes select and output_enable to generate one-hot enable signals
//-----------------------------------------------------------------------------
module tristate_demux_enable_decoder (
    input  wire [1:0] select_in,
    input  wire       output_enable_in,
    output wire [3:0] enable_out
);
    assign enable_out[0] = (output_enable_in & ~select_in[1] & ~select_in[0]);
    assign enable_out[1] = (output_enable_in & ~select_in[1] &  select_in[0]);
    assign enable_out[2] = (output_enable_in &  select_in[1] & ~select_in[0]);
    assign enable_out[3] = (output_enable_in &  select_in[1] &  select_in[0]);
endmodule

//-----------------------------------------------------------------------------
// Submodule: Tristate Buffer Array
// Description: Drives each bus line with input data when the corresponding enable is asserted
//-----------------------------------------------------------------------------
module tristate_demux_tristate_buffer_array (
    input  wire       data_in,
    input  wire [3:0] enable_in,
    output wire [3:0] bus_out
);
    assign bus_out[0] = enable_in[0] ? data_in : 1'bz;
    assign bus_out[1] = enable_in[1] ? data_in : 1'bz;
    assign bus_out[2] = enable_in[2] ? data_in : 1'bz;
    assign bus_out[3] = enable_in[3] ? data_in : 1'bz;
endmodule