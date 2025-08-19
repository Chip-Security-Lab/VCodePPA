//SystemVerilog
// Top-level module: CrossMux
// Function: Hierarchically selects input, computes parity, concatenates with selector, and outputs result

module CrossMux #(parameter DW = 8) (
    input  wire                  clk,
    input  wire [3:0][DW-1:0]    in,
    input  wire [1:0]            x_sel,
    input  wire [1:0]            y_sel,
    output wire [DW+1:0]         out
);

    // Internal signals for submodule interconnections
    wire [DW-1:0] muxed_data;
    wire          parity_bit;
    wire [DW+1:0] reg_out;

    // Input Multiplexer: Selects one of the 4 DW-bit input vectors based on x_sel
    CrossMux_InputSelector #(.DW(DW)) u_input_selector (
        .data_in  (in),
        .sel      (x_sel),
        .data_out (muxed_data)
    );

    // Parity Generator: Computes the parity of the selected data
    CrossMux_ParityGen #(.DW(DW)) u_parity_gen (
        .data_in   (muxed_data),
        .parity_out(parity_bit)
    );

    // Output Packager: Concatenates parity, data, and y_sel
    CrossMux_OutputPackager #(.DW(DW)) u_output_packager (
        .parity      (parity_bit),
        .selected_data(muxed_data),
        .y_sel       (y_sel),
        .packed_out  (reg_out)
    );

    // Output Register: Registers the packed output
    CrossMux_OutputRegister #(.DW(DW)) u_output_register (
        .clk (clk),
        .din (reg_out),
        .dout(out)
    );

endmodule

// -----------------------------------------------------------------------------
// CrossMux_InputSelector
// Selects one of the 4 DW-bit input vectors based on 2-bit selector
// -----------------------------------------------------------------------------
module CrossMux_InputSelector #(parameter DW = 8) (
    input  wire [3:0][DW-1:0] data_in,
    input  wire [1:0]         sel,
    output wire [DW-1:0]      data_out
);
    // Selects input vector based on sel
    assign data_out = data_in[sel];
endmodule

// -----------------------------------------------------------------------------
// CrossMux_ParityGen
// Calculates the parity (XOR reduction) of the input data
// -----------------------------------------------------------------------------
module CrossMux_ParityGen #(parameter DW = 8) (
    input  wire [DW-1:0] data_in,
    output wire          parity_out
);
    // Computes parity (even parity)
    assign parity_out = ^data_in;
endmodule

// -----------------------------------------------------------------------------
// CrossMux_OutputPackager
// Concatenates parity, selected data, and y_sel signals
// -----------------------------------------------------------------------------
module CrossMux_OutputPackager #(parameter DW = 8) (
    input  wire             parity,
    input  wire [DW-1:0]    selected_data,
    input  wire [1:0]       y_sel,
    output wire [DW+1:0]    packed_out
);
    // Packs the output: {parity, selected_data, y_sel}
    assign packed_out = {parity, selected_data, y_sel};
endmodule

// -----------------------------------------------------------------------------
// CrossMux_OutputRegister
// Registers the output on the rising edge of clk
// -----------------------------------------------------------------------------
module CrossMux_OutputRegister #(parameter DW = 8) (
    input  wire            clk,
    input  wire [DW+1:0]   din,
    output reg  [DW+1:0]   dout
);
    // Synchronous register for output
    always @(posedge clk) begin
        dout <= din;
    end
endmodule