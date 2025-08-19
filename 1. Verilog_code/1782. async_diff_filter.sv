module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // Simple differentiator: y[n] = x[n] - x[n-1]
    assign diff_out = {current_sample[DATA_SIZE-1], current_sample} - 
                     {prev_sample[DATA_SIZE-1], prev_sample};
endmodule