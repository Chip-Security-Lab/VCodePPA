//SystemVerilog
// Top-level module
module MuxBusHoldTop #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output [W-1:0] bus_out
);

    wire [W-1:0] mux_out;

    // Instantiate the MUX submodule
    MuxBus mux_inst (
        .bus_in(bus_in),
        .sel(sel),
        .hold(hold),
        .bus_out(mux_out)
    );

    assign bus_out = mux_out;

endmodule

// MUX submodule
module MuxBus #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] bus_out
);

    always @(*) begin
        bus_out = hold ? bus_out : bus_in[sel];
    end

endmodule