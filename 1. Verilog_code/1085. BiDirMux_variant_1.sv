//SystemVerilog
// Top-level hierarchical BiDirMux module with modularized functional blocks

module BiDirMux #(
    parameter DW = 8
)(
    inout  [DW-1:0]               bus,
    input  [(4*DW)-1:0]           tx,
    output [(4*DW)-1:0]           rx,
    input  [1:0]                  sel,
    input                         oe
);

    // Internal signals
    wire [DW-1:0] tx_selected;
    wire          bus_oe;
    wire [DW-1:0] bus_in;
    wire [DW-1:0] rx_ch [3:0];

    // TX Selector: selects which channel drives bus
    TxSelector #(.DW(DW)) u_tx_selector (
        .tx        (tx),
        .sel       (sel),
        .tx_out    (tx_selected)
    );

    // Output Enable Control: generates tri-state enable for bus
    BusOEControl u_bus_oe_control (
        .oe        (oe),
        .bus_oe    (bus_oe)
    );

    // Bidirectional Bus Buffer: drives or samples bus
    BusBuffer #(.DW(DW)) u_bus_buffer (
        .bus       (bus),
        .tx_data   (tx_selected),
        .oe        (bus_oe),
        .bus_in    (bus_in)
    );

    // RX Demultiplexer: routes bus_in to appropriate channel
    RxDemux #(.DW(DW)) u_rx_demux (
        .bus_in    (bus_in),
        .sel       (sel),
        .rx        (rx)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: TxSelector
// Selects the transmit data word based on channel select
// -----------------------------------------------------------------------------
module TxSelector #(
    parameter DW = 8
)(
    input  [(4*DW)-1:0] tx,
    input  [1:0]        sel,
    output [DW-1:0]     tx_out
);
    assign tx_out = tx[(sel*DW) +: DW];
endmodule

// -----------------------------------------------------------------------------
// Submodule: BusOEControl
// Controls the output enable for the bus buffer
// -----------------------------------------------------------------------------
module BusOEControl (
    input  oe,
    output bus_oe
);
    assign bus_oe = oe;
endmodule

// -----------------------------------------------------------------------------
// Submodule: BusBuffer
// Bidirectional bus buffer with tri-state output and bus sampling
// -----------------------------------------------------------------------------
module BusBuffer #(
    parameter DW = 8
)(
    inout  [DW-1:0] bus,
    input  [DW-1:0] tx_data,
    input           oe,
    output [DW-1:0] bus_in
);
    assign bus     = oe ? tx_data : {DW{1'bz}};
    assign bus_in  = bus;
endmodule

// -----------------------------------------------------------------------------
// Submodule: RxDemux
// Demultiplexes the bus input to the correct receive channel
// -----------------------------------------------------------------------------
module RxDemux #(
    parameter DW = 8
)(
    input  [DW-1:0]     bus_in,
    input  [1:0]        sel,
    output [(4*DW)-1:0] rx
);
    wire [DW-1:0] rx_ch [3:0];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : rx_demux_gen
            RxChannel #(.DW(DW), .CH_IDX(i)) u_rx_channel (
                .bus_in    (bus_in),
                .sel       (sel),
                .rx_out    (rx_ch[i])
            );
            assign rx[(i+1)*DW-1:i*DW] = rx_ch[i];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Submodule: RxChannel
// Receives bus data if channel selected, otherwise outputs zeros
// -----------------------------------------------------------------------------
module RxChannel #(
    parameter DW = 8,
    parameter CH_IDX = 0
)(
    input  [DW-1:0] bus_in,
    input  [1:0]    sel,
    output [DW-1:0] rx_out
);
    assign rx_out = (sel == CH_IDX) ? bus_in : {DW{1'b0}};
endmodule