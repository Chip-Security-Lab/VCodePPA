module averaging_recovery #(
    parameter WIDTH = 8,
    parameter AVG_DEPTH = 4
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] noisy_in,
    input wire sample_en,
    output reg [WIDTH-1:0] filtered_out
);
    reg [WIDTH-1:0] samples [0:AVG_DEPTH-1];
    reg [WIDTH+2:0] sum;
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < AVG_DEPTH; i = i + 1)
                samples[i] <= 0;
            sum <= 0;
            filtered_out <= 0;
        end else if (sample_en) begin
            // Shift in new sample
            for (i = AVG_DEPTH-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= noisy_in;
            
            // Calculate sum
            sum <= 0;
            for (i = 0; i < AVG_DEPTH; i = i + 1)
                sum <= sum + samples[i];
                
            // Calculate average
            filtered_out <= sum / AVG_DEPTH;
        end
    end
endmodule