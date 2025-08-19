module adaptive_threshold_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] signal_in,
    input wire [7:0] noise_level,
    output reg [7:0] signal_out,
    output reg signal_valid
);
    reg [7:0] threshold;
    
    always @(posedge clk) begin
        if (reset) begin
            threshold <= 8'd128;
            signal_out <= 8'd0;
            signal_valid <= 1'b0;
        end else begin
            // Adapt threshold based on noise level
            threshold <= 8'd64 + (noise_level >> 1);
            
            // Apply threshold
            if (signal_in > threshold) begin
                signal_out <= signal_in;
                signal_valid <= 1'b1;
            end else begin
                signal_out <= 8'd0;
                signal_valid <= 1'b0;
            end
        end
    end
endmodule