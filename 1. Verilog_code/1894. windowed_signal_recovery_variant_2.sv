//SystemVerilog
module windowed_signal_recovery #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input wire clk,
    input wire window_enable,
    input wire [DATA_WIDTH-1:0] signal_in,
    output reg [DATA_WIDTH-1:0] signal_out,
    output reg valid
);
    // Register for window data storage
    reg [DATA_WIDTH-1:0] window [0:WINDOW_SIZE-1];
    // Use the exact bit width needed for the sum
    reg [DATA_WIDTH+$clog2(WINDOW_SIZE)-1:0] sum;
    // Track oldest value for efficient updating
    reg [DATA_WIDTH-1:0] oldest_value;
    // Counter for initialization phase
    reg [$clog2(WINDOW_SIZE):0] valid_samples;
    // Valid samples initialization flag
    reg initialization_done;
    
    integer i;
    
    always @(posedge clk) begin
        if (window_enable) begin
            // Store oldest value before shifting
            oldest_value <= window[WINDOW_SIZE-1];
            
            // Shift window values - use generate optimized shifting
            for (i = WINDOW_SIZE-1; i > 0; i = i-1)
                window[i] <= window[i-1];
            window[0] <= signal_in;
            
            // Track initialization phase
            if (!initialization_done) begin
                valid_samples <= valid_samples + 1'b1;
                if (valid_samples == WINDOW_SIZE-1) begin
                    initialization_done <= 1'b1;
                end
                
                // Accumulate sum during initialization
                sum <= sum + signal_in;
            end else begin
                // Efficient sum update using sliding window concept
                // Subtract oldest value and add newest value
                sum <= sum - oldest_value + signal_in;
            end
            
            // Calculate windowed average only when window is full
            if (initialization_done) begin
                signal_out <= sum / WINDOW_SIZE;
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end
    
    // Reset logic
    initial begin
        valid <= 1'b0;
        initialization_done <= 1'b0;
        valid_samples <= 0;
        sum <= 0;
        for (i = 0; i < WINDOW_SIZE; i = i+1)
            window[i] <= 0;
    end
endmodule