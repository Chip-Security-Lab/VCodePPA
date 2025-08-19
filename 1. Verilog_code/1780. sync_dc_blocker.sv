module sync_dc_blocker #(
    parameter WIDTH = 16
)(
    input clk, reset,
    input [WIDTH-1:0] signal_in,
    output reg [WIDTH-1:0] signal_out
);
    reg [WIDTH-1:0] prev_in, prev_out;
    wire [WIDTH-1:0] temp;
    
    // DC blocker: y[n] = x[n] - x[n-1] + 0.995*y[n-1]
    // Simplified version with 0.875 coefficient (7/8)
    assign temp = signal_in - prev_in + ((prev_out * 7) >> 3);
    
    always @(posedge clk) begin
        if (reset) begin
            prev_in <= 0;
            prev_out <= 0;
            signal_out <= 0;
        end else begin
            prev_in <= signal_in;
            prev_out <= temp;
            signal_out <= temp;
        end
    end
endmodule