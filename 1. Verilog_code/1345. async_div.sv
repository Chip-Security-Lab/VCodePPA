module async_div #(parameter DIV=4) (
    input clk_in,
    output wire clk_out
);
reg [3:0] cnt;

always @(posedge clk_in) begin
    cnt <= cnt + 1;
end
    
assign clk_out = (DIV <= 4) ? |cnt[DIV-1:1] : |cnt[3:1];
endmodule