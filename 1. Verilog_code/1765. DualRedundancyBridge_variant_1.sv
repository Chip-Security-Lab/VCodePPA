//SystemVerilog
module DualRedundancyBridge(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    output reg [31:0] data_out,
    output reg error
);
    always @(posedge clk) begin
        error <= (data_a !== data_b);
        data_out <= (data_a !== data_b) ? 32'b0 : data_a;
    end
endmodule