//SystemVerilog
module peak_detection_recovery (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output reg [9:0] peak_value,
    output reg peak_detected
);
    // History registers
    reg [9:0] prev_value;
    reg [9:0] prev_prev_value;
    
    // Split comparison logic into separate paths
    reg prev_greater_than_prev_prev;
    reg prev_greater_than_current;
    
    // Peak detection intermediate signal
    reg peak_condition;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 10'h0;
            prev_prev_value <= 10'h0;
            prev_greater_than_prev_prev <= 1'b0;
            prev_greater_than_current <= 1'b0;
            peak_condition <= 1'b0;
            peak_detected <= 1'b0;
            peak_value <= 10'h0;
        end else begin
            // Update history registers - first pipeline stage
            prev_prev_value <= prev_value;
            prev_value <= signal_in;
            
            // Pre-compute comparisons in parallel - second pipeline stage
            // Splitting comparisons into independent paths reduces logic depth
            prev_greater_than_prev_prev <= (prev_value > prev_prev_value);
            prev_greater_than_current <= (prev_value > signal_in);
            
            // Combine pre-computed results - third pipeline stage
            peak_condition <= prev_greater_than_prev_prev && prev_greater_than_current;
            
            // Final stage - use peak condition to update outputs
            peak_detected <= peak_condition;
            
            // Only update peak value when condition is true
            // Moved condition to separate register to reduce critical path
            if (peak_condition) begin
                peak_value <= prev_value;
            end
        end
    end
endmodule