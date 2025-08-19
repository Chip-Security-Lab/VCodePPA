//SystemVerilog
// Top level module
module MuxTree #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);

    // Internal signals
    wire [W-1:0] mux_out;
    
    // Instantiate selector module
    Selector #(
        .W(W),
        .N(N)
    ) selector_inst (
        .din(din),
        .sel(sel),
        .dout(mux_out)
    );

    // Output assignment
    assign dout = mux_out;

endmodule

// Selector submodule
module Selector #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);

    // Direct selection logic
    assign dout = din[sel];

endmodule