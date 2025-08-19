//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: async_rst_low_comb_top.v
// Description: Top module for asynchronous low-active reset combinational logic
// Standard: IEEE 1364-2005 (Verilog-2005)
///////////////////////////////////////////////////////////////////////////////

module async_rst_low_comb #(
    parameter WIDTH = 16
)(
    input  wire           rst_n,
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);

    // Internal signals
    wire reset_active;
    wire [WIDTH-1:0] reset_value;
    wire [WIDTH-1:0] data_gated;

    // Reset detection submodule
    reset_detector u_reset_detector (
        .rst_n        (rst_n),
        .reset_active (reset_active)
    );

    // Reset value generator submodule
    reset_value_gen #(
        .WIDTH        (WIDTH)
    ) u_reset_value_gen (
        .reset_value  (reset_value)
    );

    // Data path control submodule
    data_path_control #(
        .WIDTH        (WIDTH)
    ) u_data_path_control (
        .reset_active (reset_active),
        .reset_value  (reset_value),
        .in_data      (in_data),
        .data_gated   (data_gated)
    );

    // Output assignment
    assign out_data = data_gated;

endmodule

///////////////////////////////////////////////////////////////////////////////
// Reset detector submodule
///////////////////////////////////////////////////////////////////////////////

module reset_detector (
    input  wire rst_n,
    output wire reset_active
);

    // Active low reset detection (inverted for internal logic)
    assign reset_active = ~rst_n;

endmodule

///////////////////////////////////////////////////////////////////////////////
// Reset value generator submodule
///////////////////////////////////////////////////////////////////////////////

module reset_value_gen #(
    parameter WIDTH = 16
)(
    output wire [WIDTH-1:0] reset_value
);

    // Generate the reset value (always zeros in this design)
    assign reset_value = {WIDTH{1'b0}};

endmodule

///////////////////////////////////////////////////////////////////////////////
// Data path control submodule
///////////////////////////////////////////////////////////////////////////////

module data_path_control #(
    parameter WIDTH = 16
)(
    input  wire           reset_active,
    input  wire [WIDTH-1:0] reset_value,
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] data_gated
);

    // Select between input data and reset value based on reset status
    assign data_gated = reset_active ? reset_value : in_data;

endmodule