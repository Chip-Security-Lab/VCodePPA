module ReloadTimer #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] reload_val,
    output reg timeout
);
reg [DW-1:0] cnt;
wire reload = timeout || !rst_n;
always @(posedge clk) begin
    cnt <= reload ? reload_val : cnt - 1;
    timeout <= (cnt == 1);
end
endmodule