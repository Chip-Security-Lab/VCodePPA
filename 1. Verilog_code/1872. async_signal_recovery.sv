module async_signal_recovery (
    input wire [7:0] noisy_input,
    input wire signal_present,
    output wire [7:0] recovered_signal
);
    wire [7:0] filtered_signal;
    
    assign filtered_signal = signal_present ? noisy_input : 8'b0;
    assign recovered_signal = (filtered_signal > 8'd128) ? 8'hFF : 8'h00;
endmodule