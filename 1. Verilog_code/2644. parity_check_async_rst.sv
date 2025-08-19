module parity_check_async_rst (
    input clk, arst,
    input [3:0] addr,
    input [7:0] data,
    output reg parity
);
always @(posedge clk or posedge arst) begin
    if (arst) parity <= 1'b0;
    else parity <= ~(^data);
end
endmodule