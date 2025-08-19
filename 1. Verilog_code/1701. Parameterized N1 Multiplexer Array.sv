module param_mux_array #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8,
    parameter SEL_BITS = $clog2(CHANNELS)
)(
    input [WIDTH-1:0] data_in [0:CHANNELS-1],
    input [SEL_BITS-1:0] channel_sel,
    output [WIDTH-1:0] data_out
);
    assign data_out = data_in[channel_sel];
endmodule