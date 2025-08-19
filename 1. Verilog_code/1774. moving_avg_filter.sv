module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    reg [DATA_W-1:0] samples [DEPTH-1:0];
    reg [DATA_W+LOG2_DEPTH-1:0] sum;
    integer i;
    
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                samples[i] <= 0;
            sum <= 0;
            data_o <= 0;
        end else if (enable) begin
            // Shift in new sample, update sum
            sum <= sum - samples[DEPTH-1] + data_i;
            for (i = DEPTH-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= data_i;
            data_o <= sum >> LOG2_DEPTH;
        end
    end
endmodule