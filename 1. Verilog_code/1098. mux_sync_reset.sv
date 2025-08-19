module mux_sync_reset (
    input wire clk,               // Clock input
    input wire rst,               // Synchronous reset
    input wire [7:0] input_0, input_1, // Data inputs
    input wire sel_line,          // Selection input
    output reg [7:0] mux_result   // Registered output
);
    always @(posedge clk) begin
        if (rst)
            mux_result <= 8'b0;   // Reset to zero
        else
            mux_result <= sel_line ? input_1 : input_0;
    end
endmodule
