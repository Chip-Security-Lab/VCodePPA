module async_multi_rate_filter #(
    parameter W = 10
)(
    input [W-1:0] fast_in,
    input [W-1:0] slow_in,
    input [3:0] alpha,  // Blend factor 0-15
    output [W-1:0] filtered_out
);
    // Blend between fast and slow signals based on alpha
    wire [W+4-1:0] fast_scaled, slow_scaled;
    
    assign fast_scaled = fast_in * alpha;
    assign slow_scaled = slow_in * (16 - alpha);
    assign filtered_out = (fast_scaled + slow_scaled) >> 4;
endmodule