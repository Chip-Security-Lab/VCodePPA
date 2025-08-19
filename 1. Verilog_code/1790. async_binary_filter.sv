module async_binary_filter #(
    parameter W = 8
)(
    input [W-1:0] analog_in,
    input [W-1:0] threshold,
    output binary_out
);
    // Simple binary threshold filter
    assign binary_out = (analog_in >= threshold) ? 1'b1 : 1'b0;
endmodule