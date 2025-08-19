//SystemVerilog
module param_signal_recovery #(
    parameter SIGNAL_WIDTH = 12,
    parameter THRESHOLD = 2048,
    parameter NOISE_MARGIN = 256
)(
    input wire sample_clk,
    input wire [SIGNAL_WIDTH-1:0] input_signal,
    output reg [SIGNAL_WIDTH-1:0] recovered_signal
);
    // Precompute thresholds to reduce critical path
    localparam [SIGNAL_WIDTH-1:0] LOWER_BOUND = THRESHOLD - NOISE_MARGIN;
    localparam [SIGNAL_WIDTH-1:0] UPPER_BOUND = THRESHOLD + NOISE_MARGIN;
    
    // Use registered thresholds to improve timing
    reg lower_check, upper_check;
    reg [SIGNAL_WIDTH-1:0] input_signal_reg;
    
    // First stage: register input and perform comparisons
    always @(posedge sample_clk) begin
        input_signal_reg <= input_signal;
        lower_check <= (input_signal >= LOWER_BOUND);
        upper_check <= (input_signal <= UPPER_BOUND);
    end
    
    // Second stage: evaluate final condition and update output
    always @(posedge sample_clk) begin
        if (lower_check && upper_check) begin
            recovered_signal <= input_signal_reg;
        end
    end
endmodule