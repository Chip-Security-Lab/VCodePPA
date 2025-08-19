module param_signal_recovery #(
    parameter SIGNAL_WIDTH = 12,
    parameter THRESHOLD = 2048,  // 使用十进制值替代SIGNAL_WIDTH'h800
    parameter NOISE_MARGIN = 256 // 使用十进制值替代SIGNAL_WIDTH'h100
)(
    input wire sample_clk,
    input wire [SIGNAL_WIDTH-1:0] input_signal,
    output reg [SIGNAL_WIDTH-1:0] recovered_signal
);
    wire valid_signal = (input_signal > THRESHOLD - NOISE_MARGIN) && 
                        (input_signal < THRESHOLD + NOISE_MARGIN);
    
    always @(posedge sample_clk) begin
        recovered_signal <= valid_signal ? input_signal : recovered_signal;
    end
endmodule