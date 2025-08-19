module base_addr_decoder #(
    parameter BASE_ADDR = 4'h0
)(
    input clk,
    input [3:0] addr,
    output reg cs
);
    always @(posedge clk) begin
        cs <= (addr[3:2] == BASE_ADDR[3:2]);
    end
endmodule