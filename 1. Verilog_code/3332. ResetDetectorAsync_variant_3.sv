//SystemVerilog
module ResetDetectorAsync (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);

//-----------------------------------------------------------------------------
// Reset signal synchronous capture
//-----------------------------------------------------------------------------
reg rst_n_sync;

always @(posedge clk or negedge rst_n) begin
    rst_n_sync <= (!rst_n) ? 1'b0 : 1'b1;
end

//-----------------------------------------------------------------------------
// Reset detected output logic
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    reset_detected <= (!rst_n) ? 1'b1 : 1'b0;
end

endmodule