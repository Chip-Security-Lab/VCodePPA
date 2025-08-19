module demux_sync_reset (
    input wire clk,                     // Clock signal
    input wire rst,                     // Synchronous reset
    input wire data_in,                 // Input data
    input wire [1:0] sel_addr,          // Selection address
    output reg [3:0] data_out           // Output ports
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0;           // Reset all outputs
        else begin
            data_out <= 4'b0;           // Clear previous state
            data_out[sel_addr] <= data_in; // Set selected output
        end
    end
endmodule