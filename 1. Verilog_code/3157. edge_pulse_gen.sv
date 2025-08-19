module edge_pulse_gen(
    input clk,
    input signal_in,
    output reg pulse_out
);
    reg signal_d;
    
    always @(posedge clk) begin
        signal_d <= signal_in;
        pulse_out <= signal_in & ~signal_d;  // Positive edge detector
    end
endmodule