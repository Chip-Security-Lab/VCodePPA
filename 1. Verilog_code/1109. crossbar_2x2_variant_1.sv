//SystemVerilog
// Top-level crossbar 2x2 module
module crossbar_2x2 (
    input wire [7:0] in0, in1,       // Input ports
    input wire [1:0] select,         // Selection control (2 bits)
    output wire [7:0] out0, out1     // Output ports
);

    // Internal wires to connect submodules
    wire [7:0] mux0_out;
    wire [7:0] mux1_out;

    // Submodule: 8-bit 2-to-1 multiplexer for out0
    crossbar_mux_2to1 #(
        .DATA_WIDTH(8)
    ) mux_out0 (
        .data0 (in0),
        .data1 (in1),
        .sel   (select[0]),
        .mux_out (mux0_out)
    );

    // Submodule: 8-bit 2-to-1 multiplexer for out1
    crossbar_mux_2to1 #(
        .DATA_WIDTH(8)
    ) mux_out1 (
        .data0 (in0),
        .data1 (in1),
        .sel   (select[1]),
        .mux_out (mux1_out)
    );

    // Output assignments
    assign out0 = mux0_out;
    assign out1 = mux1_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: crossbar_mux_2to1
// Description: Parameterized 2-to-1 multiplexer for crossbar switching.
// -----------------------------------------------------------------------------
module crossbar_mux_2to1 #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] data0,   // Input 0
    input  wire [DATA_WIDTH-1:0] data1,   // Input 1
    input  wire                  sel,     // Select signal
    output wire [DATA_WIDTH-1:0] mux_out  // Multiplexer output
);
    assign mux_out = sel ? data1 : data0;
endmodule