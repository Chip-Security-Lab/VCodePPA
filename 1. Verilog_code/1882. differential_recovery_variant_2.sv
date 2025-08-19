//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module differential_recovery (
    input wire clk,
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    output reg [8:0] recovered_signal
);
    // Buffered pos_signal to reduce fanout
    reg [7:0] pos_signal_buf1;
    reg [7:0] pos_signal_buf2;
    
    // Pre-compute differences and comparison
    wire pos_greater_eq;
    wire [7:0] pos_minus_neg;
    wire [7:0] neg_minus_pos;
    
    // Buffer the high fanout signal in the first pipeline stage
    always @(posedge clk) begin
        pos_signal_buf1 <= pos_signal;
        pos_signal_buf2 <= pos_signal;
    end
    
    // Use buffered signals for comparison and subtraction
    assign pos_greater_eq = (pos_signal_buf1 >= neg_signal);
    assign pos_minus_neg = pos_signal_buf1 - neg_signal;
    assign neg_minus_pos = neg_signal - pos_signal_buf2;
    
    always @(posedge clk) begin
        // Use pre-computed values to improve timing
        recovered_signal <= pos_greater_eq ? {1'b0, pos_minus_neg} : {1'b1, neg_minus_pos};
    end
endmodule