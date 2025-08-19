module EdgeDetectLatch (
    input clk, sig_in,
    output reg rising, falling
);
reg last_sig;
always @(posedge clk) begin
    last_sig <= sig_in;
    rising <= sig_in & ~last_sig;
    falling <= ~sig_in & last_sig;
end
endmodule