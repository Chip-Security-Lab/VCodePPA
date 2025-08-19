module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    assign mux_out = sel ? (val + 4'd5) : (val - 4'd3);
    assign invert = ~val;
endmodule
