//SystemVerilog
module Demux_CDC #(parameter DW=8) (
    input clk_a, clk_b,
    input [DW-1:0] data_a,
    input sel_a,
    output reg [DW-1:0] data_b0,
    output reg [DW-1:0] data_b1
);

reg [DW-1:0] sync0, sync1;

always @(posedge clk_a) begin
    if (sel_a) begin
        sync0 <= data_a;
        sync1 <= 0;
    end else begin
        sync0 <= 0;
        sync1 <= data_a;
    end
end

always @(posedge clk_b) begin
    data_b0 <= sync0;
    data_b1 <= sync1;
end

endmodule