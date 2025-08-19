module MuxBidir #(parameter W=8) (
    inout [W-1:0] bus_a,
    inout [W-1:0] bus_b,
    output [W-1:0] bus_out,
    input sel, oe
);
assign bus_a = (sel && oe) ? bus_out : 'bz;
assign bus_b = (!sel && oe) ? bus_out : 'bz;
assign bus_out = sel ? bus_a : bus_b;
endmodule