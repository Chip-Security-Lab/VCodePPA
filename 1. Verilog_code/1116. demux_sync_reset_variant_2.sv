//SystemVerilog
module demux_sync_reset (
    input wire clk,                      // Clock signal
    input wire rst,                      // Synchronous reset
    input wire data_in,                  // Input data
    input wire [1:0] sel_addr,           // Selection address
    output reg [3:0] data_out            // Output ports
);

    wire [3:0] data_out_comb;

    assign data_out_comb = 4'b0 | (data_in << sel_addr);

    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0;                  // Reset all outputs
        else
            data_out <= data_out_comb;         // Set selected output
    end

endmodule