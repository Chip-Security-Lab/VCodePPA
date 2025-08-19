module fixed_point #(parameter Q=4, DW=8) (
    input signed [DW-1:0] in,
    output signed [DW-1:0] out
);
    assign out = in >>> Q;
endmodule
