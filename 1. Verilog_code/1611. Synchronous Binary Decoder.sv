module sync_binary_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [OUT_WIDTH-1:0] sel_out
);
    always @(posedge clk) begin
        sel_out <= 1'b1 << addr;
    end
endmodule