//SystemVerilog
module async_debounce_filter #(
    parameter STABLE_COUNT = 8,
    parameter THRESHOLD = STABLE_COUNT/2
)(
    input noisy_signal,
    input [3:0] curr_state,
    output reg [3:0] next_state,
    output clean_signal
);
    // Optimized state transition logic
    always @(*) begin
        // Default case to prevent latches
        next_state = curr_state;
        
        if (noisy_signal) begin
            // Rising edge path - only increment if not at max
            if (curr_state < STABLE_COUNT)
                next_state = curr_state + 1'b1;
        end else begin
            // Falling edge path - only decrement if not at min
            if (|curr_state) // Efficient non-zero check
                next_state = curr_state - 1'b1;
        end
    end
    
    // Optimized comparison for clean signal using single comparison
    assign clean_signal = curr_state >= THRESHOLD;
endmodule