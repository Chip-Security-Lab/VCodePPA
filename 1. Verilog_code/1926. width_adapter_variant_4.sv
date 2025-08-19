//SystemVerilog
// Top-level width adapter module with hierarchical submodules

module width_adapter #(
    parameter IN_DW = 32,
    parameter OUT_DW = 16
)(
    input  [IN_DW-1:0]  data_in,
    input               sign_extend,
    output [OUT_DW-1:0] data_out
);

    wire high_bits_nonzero;
    wire extend_enable;
    wire [OUT_DW-1:0] extended_data;
    wire [OUT_DW-1:0] truncated_data;

    // High bits detection submodule
    high_bits_detector #(
        .IN_DW(IN_DW),
        .OUT_DW(OUT_DW)
    ) u_high_bits_detector (
        .data_in      (data_in),
        .high_nonzero (high_bits_nonzero)
    );

    // Sign extend enable logic submodule
    sign_extend_enabler u_sign_extend_enabler (
        .high_nonzero (high_bits_nonzero),
        .sign_extend  (sign_extend),
        .extend_en    (extend_enable)
    );

    // Data extension/truncation submodule
    data_extender #(
        .IN_DW(IN_DW),
        .OUT_DW(OUT_DW)
    ) u_data_extender (
        .data_in      (data_in),
        .extend_en    (extend_enable),
        .data_out     (extended_data)
    );

    // Data truncation submodule
    data_truncator #(
        .IN_DW(IN_DW),
        .OUT_DW(OUT_DW)
    ) u_data_truncator (
        .data_in      (data_in),
        .data_out     (truncated_data)
    );

    // Output selection logic
    assign data_out = extend_enable ? extended_data : truncated_data;

endmodule

// ---------------------------------------------------------------------------

// Submodule: high_bits_detector
// Description: Detects if any of the high bits (above OUT_DW) are non-zero.
module high_bits_detector #(
    parameter IN_DW = 32,
    parameter OUT_DW = 16
)(
    input  [IN_DW-1:0] data_in,
    output             high_nonzero
);
    assign high_nonzero = |data_in[IN_DW-1:OUT_DW];
endmodule

// ---------------------------------------------------------------------------

// Submodule: sign_extend_enabler
// Description: Determines if sign extension should be enabled.
module sign_extend_enabler (
    input  high_nonzero,
    input  sign_extend,
    output extend_en
);
    assign extend_en = high_nonzero & sign_extend;
endmodule

// ---------------------------------------------------------------------------

// Submodule: data_extender
// Description: Performs sign extension on the lower OUT_DW bits when enabled.
module data_extender #(
    parameter IN_DW = 32,
    parameter OUT_DW = 16
)(
    input  [IN_DW-1:0]  data_in,
    input               extend_en,
    output [OUT_DW-1:0] data_out
);
    wire [OUT_DW-1:0] sign_ext_bits;
    assign sign_ext_bits = {OUT_DW{data_in[IN_DW-1]}};
    assign data_out = sign_ext_bits ^ data_in[OUT_DW-1:0] ^ {OUT_DW{1'b0}};
endmodule

// ---------------------------------------------------------------------------

// Submodule: data_truncator
// Description: Truncates the input data to the lower OUT_DW bits.
module data_truncator #(
    parameter IN_DW = 32,
    parameter OUT_DW = 16
)(
    input  [IN_DW-1:0]  data_in,
    output [OUT_DW-1:0] data_out
);
    assign data_out = data_in[OUT_DW-1:0];
endmodule