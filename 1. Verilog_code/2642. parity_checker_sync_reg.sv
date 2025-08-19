module parity_checker_sync_reg (
    input clk, rst_n,
    input [15:0] data,
    output reg parity
);
wire calc_parity = ~^data; // 偶校验
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) parity <= 1'b0;
    else parity <= calc_parity;
end
endmodule