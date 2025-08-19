//SystemVerilog
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
    wire [DW:0] borrow; // Borrow bits for subtraction
    wire [2*DW-1:0] scaled_diff;
    
    // Implement borrow subtraction
    assign borrow[0] = 1'b0; // No initial borrow
    
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin: borrow_subtractor
            assign diff[i] = next_sample[i] ^ prev_sample[i] ^ borrow[i];
            assign borrow[i+1] = (prev_sample[i] & borrow[i]) | 
                               (~next_sample[i] & prev_sample[i]) | 
                               (~next_sample[i] & borrow[i]);
        end
    endgenerate
    
    assign scaled_diff = diff * frac;
    assign interp_out = prev_sample + scaled_diff[2*DW-1:DW];
endmodule