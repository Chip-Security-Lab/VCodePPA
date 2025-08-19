//SystemVerilog
// Top-level bidirectional multiplexer module with hierarchical structure
module BiDirMux #(parameter DW=8) (
    inout  [DW-1:0]             bus,
    input  [(4*DW)-1:0]         tx,
    output [(4*DW)-1:0]         rx,
    input  [1:0]                sel,
    input                       oe
);

    wire [DW-1:0]               bus_out;
    wire [DW-1:0]               bus_in;
    wire                        bus_drive_enable;

    // Output multiplexer: selects which tx to drive onto the bus
    OutputMux #(.DW(DW)) u_output_mux (
        .tx           (tx),
        .sel          (sel),
        .oe           (oe),
        .bus_drive    (bus_drive_enable),
        .bus_out      (bus_out)
    );

    // Bidirectional bus buffer: drives or receives data from the bus
    BusBuffer #(.DW(DW)) u_bus_buffer (
        .bus          (bus),
        .bus_drive    (bus_drive_enable),
        .bus_out      (bus_out),
        .bus_in       (bus_in)
    );

    // Input demultiplexer: captures bus data into one of the rx outputs
    InputDemux #(.DW(DW)) u_input_demux (
        .bus_in       (bus_in),
        .sel          (sel),
        .rx           (rx)
    );

endmodule

// -----------------------------------------------------------------------------
// OutputMux: Selects one tx segment based on sel and controls bus drive enable
// -----------------------------------------------------------------------------
module OutputMux #(parameter DW=8) (
    input  [(4*DW)-1:0] tx,
    input  [1:0]        sel,
    input               oe,
    output              bus_drive,
    output [DW-1:0]     bus_out
);
    assign bus_out = tx[(sel*DW) +: DW];
    assign bus_drive = oe;
endmodule

// -----------------------------------------------------------------------------
// BusBuffer: Bidirectional buffer for the bus (tristate)
// -----------------------------------------------------------------------------
module BusBuffer #(parameter DW=8) (
    inout  [DW-1:0] bus,
    input           bus_drive,
    input  [DW-1:0] bus_out,
    output [DW-1:0] bus_in
);
    // Drive bus when enabled, otherwise high-Z
    assign bus = bus_drive ? bus_out : {DW{1'bz}};
    // Always sample bus value
    assign bus_in = bus;
endmodule

// -----------------------------------------------------------------------------
// InputDemux: Demultiplexes bus_in to the correct rx slice based on sel
// -----------------------------------------------------------------------------
module InputDemux #(parameter DW=8) (
    input  [DW-1:0]     bus_in,
    input  [1:0]        sel,
    output [(4*DW)-1:0] rx
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: rx_assign
            assign rx[(i+1)*DW-1:i*DW] = (sel == i) ? bus_in : {DW{1'bz}};
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// 2-bit Conditional Invert Subtractor Unit
// -----------------------------------------------------------------------------
module Subtractor2Bit_CondInv (
    input  [1:0] minuend,
    input  [1:0] subtrahend,
    output [1:0] difference,
    output       borrow_out
);
    wire [1:0]  subtrahend_inv;
    wire [2:0]  carry;
    wire [1:0]  sum;

    // Conditional inversion of subtrahend (for subtraction: A - B = A + (~B) + 1)
    assign subtrahend_inv = ~subtrahend;

    // Ripple-carry adder logic for 2 bits, initial carry-in is 1 (for two's complement)
    assign carry[0] = 1'b1;

    assign sum[0] = minuend[0] ^ subtrahend_inv[0] ^ carry[0];
    assign carry[1] = (minuend[0] & subtrahend_inv[0]) | (minuend[0] & carry[0]) | (subtrahend_inv[0] & carry[0]);

    assign sum[1] = minuend[1] ^ subtrahend_inv[1] ^ carry[1];
    assign carry[2] = (minuend[1] & subtrahend_inv[1]) | (minuend[1] & carry[1]) | (subtrahend_inv[1] & carry[1]);

    assign difference = sum;
    assign borrow_out = ~carry[2];

endmodule