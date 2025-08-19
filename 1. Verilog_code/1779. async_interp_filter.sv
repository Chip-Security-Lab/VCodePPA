module async_interp_filter #(
    parameter DW = 10
)(
    input [DW-1:0] prev_sample,
    input [DW-1:0] next_sample,
    input [$clog2(DW)-1:0] frac,
    output [DW-1:0] interp_out
);
    // Linear interpolation: out = prev + frac*(next-prev)
    wire [DW-1:0] diff;
    wire [2*DW-1:0] scaled_diff;
    
    assign diff = next_sample - prev_sample;
    assign scaled_diff = diff * frac;
    assign interp_out = prev_sample + scaled_diff[2*DW-1:DW];
endmodule