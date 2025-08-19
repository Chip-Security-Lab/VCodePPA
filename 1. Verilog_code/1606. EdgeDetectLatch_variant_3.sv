//SystemVerilog
module EdgeDetectLatch (
    input clk, sig_in,
    output reg rising, falling
);

reg last_sig;
reg sig_in_buf;
reg sig_in_buf2;  // Additional buffer stage

always @(posedge clk) begin
    sig_in_buf <= sig_in;
    sig_in_buf2 <= sig_in_buf;  // Second buffer stage
    last_sig <= sig_in_buf2;    // Use buffered signal
    rising <= sig_in_buf2 & ~last_sig;
    falling <= ~sig_in_buf2 & last_sig;
end

endmodule