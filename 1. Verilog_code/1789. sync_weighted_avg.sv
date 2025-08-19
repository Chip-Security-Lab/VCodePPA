module sync_weighted_avg #(
    parameter DW = 12,
    parameter WEIGHTS = 3
)(
    input clk, rstn,
    input [DW-1:0] sample_in,
    input [7:0] weights [WEIGHTS-1:0],
    output reg [DW-1:0] filtered_out
);
    reg [DW-1:0] samples [WEIGHTS-1:0];
    reg [DW+8-1:0] weighted_sum;
    reg [7:0] weight_sum;
    integer i;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < WEIGHTS; i = i + 1)
                samples[i] <= 0;
            filtered_out <= 0;
        end else begin
            // Shift samples through delay line
            for (i = WEIGHTS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= sample_in;
            
            // Calculate weighted sum and weight sum
            weighted_sum = 0;
            weight_sum = 0;
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                weighted_sum = weighted_sum + samples[i] * weights[i];
                weight_sum = weight_sum + weights[i];
            end
            
            // Normalize by sum of weights
            filtered_out <= weighted_sum / weight_sum;
        end
    end
endmodule