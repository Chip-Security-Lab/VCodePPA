//SystemVerilog
module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    // Optimized memory structure - single buffer with improved access pattern
    reg [DATA_W-1:0] samples [DEPTH-1:0];
    
    // Use a direct sum calculation instead of buffering
    reg [DATA_W+LOG2_DEPTH-1:0] sum;
    
    // Pipelined control signals for better timing
    reg enable_p1;
    reg reset_n_p1;
    
    // Capture the oldest sample for more efficient subtraction
    reg [DATA_W-1:0] oldest_sample;
    
    integer i;
    
    always @(posedge clk) begin
        // First stage pipeline registers
        enable_p1 <= enable;
        reset_n_p1 <= reset_n;
        
        // Store oldest sample for efficient subtraction
        oldest_sample <= samples[DEPTH-1];
        
        if (!reset_n_p1) begin
            // Reset condition with simplified loop
            for (i = 0; i < DEPTH; i = i + 1)
                samples[i] <= '0;
            sum <= '0;
            data_o <= '0;
        end 
        else if (enable_p1) begin
            // Optimize sum calculation - direct subtraction of oldest sample
            sum <= sum - oldest_sample + data_i;
            
            // Optimized shift using a more efficient indexing pattern
            // This creates a more predictable access pattern for synthesis
            for (i = DEPTH-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            
            samples[0] <= data_i;
            
            // Right shift using parameter directly for better inference of arithmetic shift
            data_o <= (sum + (1'b1 << (LOG2_DEPTH-1))) >> LOG2_DEPTH; // Improved rounding
        end
    end
endmodule