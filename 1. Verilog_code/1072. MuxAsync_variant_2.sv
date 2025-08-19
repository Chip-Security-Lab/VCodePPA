//SystemVerilog
// Top-level module: Hierarchical restructuring of original MuxAsync design

module MuxAsync #(parameter DW=8, AW=3) (
    input  [AW-1:0]                channel,
    input  [2**AW-1:0][DW-1:0]     din,
    output [DW-1:0]                dout
);

    // Internal wires for submodule connections
    wire [DW-1:0] mux_data_out;
    wire [DW-1:0] sub_min;
    wire [DW-1:0] sub_sub;
    wire [DW-1:0] sub_diff;
    wire          sub_borrow;

    // Channel multiplexer: selects channel data from input array
    MuxChannel #(
        .DW(DW),
        .AW(AW)
    ) u_mux_channel (
        .sel      (channel),
        .din      (din),
        .dout     (mux_data_out)
    );

    // Assign minuend and subtrahend for subtractor
    assign sub_min = din[0];
    assign sub_sub = din[1];

    // 8-bit borrow lookahead subtractor
    BorrowLookaheadSubtractor #(
        .DW(8)
    ) u_borrow_lookahead_subtractor (
        .a     (sub_min),
        .b     (sub_sub),
        .bin   (1'b0),
        .diff  (sub_diff),
        .bout  (sub_borrow)
    );

    // Output assignment (change to sub_diff if subtraction result is desired)
    assign dout = mux_data_out;

endmodule

// -----------------------------------------------------------------------------
// MuxChannel: Parameterized multiplexer for selecting one data channel
// -----------------------------------------------------------------------------
module MuxChannel #(parameter DW=8, AW=3) (
    input  [AW-1:0]                sel,
    input  [2**AW-1:0][DW-1:0]     din,
    output [DW-1:0]                dout
);
    assign dout = din[sel];
endmodule

// -----------------------------------------------------------------------------
// BorrowLookaheadSubtractor: Parameterized n-bit borrow lookahead subtractor
// DW must be set to 8 for compatibility with top-level instantiation
// -----------------------------------------------------------------------------
module BorrowLookaheadSubtractor #(parameter DW=8) (
    input  [DW-1:0] a,
    input  [DW-1:0] b,
    input           bin,
    output [DW-1:0] diff,
    output          bout
);
    // Propagate and generate signals
    wire [DW-1:0] p;
    wire [DW-1:0] g;
    wire [DW-1:0] b_wire;

    assign p = ~(a ^ b);
    assign g = (~a) & b;

    // Borrow lookahead chain
    assign b_wire[0] = g[0] | (p[0] & bin);

    genvar i;
    generate
        for (i = 1; i < DW; i = i + 1) begin : borrow_chain
            assign b_wire[i] = g[i] | (p[i] & b_wire[i-1]);
        end
    endgenerate

    assign diff = a ^ b ^ {b_wire[DW-2:0], bin};
    assign bout = b_wire[DW-1];
endmodule