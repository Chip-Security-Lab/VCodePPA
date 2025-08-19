module async_debounce_filter #(
    parameter STABLE_COUNT = 8
)(
    input noisy_signal,
    input [3:0] curr_state,
    output reg [3:0] next_state,
    output clean_signal
);
    always @(*) begin
        if (noisy_signal == 1'b1 && curr_state < STABLE_COUNT)
            next_state = curr_state + 1;
        else if (noisy_signal == 1'b0 && curr_state > 0)
            next_state = curr_state - 1;
        else
            next_state = curr_state;
    end
    
    // Signal is considered stable when counter reaches threshold
    assign clean_signal = (curr_state >= STABLE_COUNT/2) ? 1'b1 : 1'b0;
endmodule