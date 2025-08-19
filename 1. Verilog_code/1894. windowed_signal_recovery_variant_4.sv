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
    reg [DATA_WIDTH-1:0] window [0:WINDOW_SIZE-1];
    reg [DATA_WIDTH+3:0] running_sum;
    reg update_window;
    reg compute_avg;
    
    // Control logic - generate control signals
    always @(posedge clk) begin
        update_window <= window_enable;
        compute_avg <= update_window;
    end
    
    // Window update logic
    always @(posedge clk) begin
        if (window_enable) begin
            // Shift window values efficiently
            for (integer i = WINDOW_SIZE-1; i > 0; i = i-1)
                window[i] <= window[i-1];
            window[0] <= signal_in;
        end
    end
    
    // Running sum logic
    always @(posedge clk) begin
        if (window_enable) begin
            // Update running sum directly (subtract oldest, add newest)
            running_sum <= running_sum - window[WINDOW_SIZE-1] + signal_in;
        end
    end
    
    // Average calculation logic
    always @(posedge clk) begin
        if (update_window) begin
            // Calculate windowed average using running sum
            signal_out <= running_sum / WINDOW_SIZE;
        end
    end
    
    // Valid signal generation
    always @(posedge clk) begin
        valid <= compute_avg;
    end
    
    // Initialize running sum and window
    initial begin
        running_sum = 0;
        for (integer i = 0; i < WINDOW_SIZE; i = i+1)
            window[i] = 0;
        valid = 0;
        update_window = 0;
        compute_avg = 0;
    end
endmodule