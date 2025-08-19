module demux_async_reset (
    input wire clk,                      // Clock signal
    input wire rst_n,                    // Active-low async reset
    input wire data,                     // Input data
    input wire [2:0] channel,            // Channel selection
    output reg [7:0] out_channels        // Output channels
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_channels <= 8'b0;         // Reset on async signal
        else begin
            out_channels <= 8'b0;         // Clear all outputs
            out_channels[channel] <= data; // Set the selected channel
        end
    end
endmodule