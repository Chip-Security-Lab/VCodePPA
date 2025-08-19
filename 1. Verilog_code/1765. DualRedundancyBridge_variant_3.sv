//SystemVerilog
module DualRedundancyBridge(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    output reg [31:0] data_out,
    output reg error
);
    always @(posedge clk) begin
        if (data_a !== data_b) begin
            error <= 1'b1;
            data_out <= 32'b0;
        end else begin
            error <= 1'b0;
            data_out <= data_a;
        end
    end
endmodule