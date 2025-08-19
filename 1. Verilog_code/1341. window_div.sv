module window_div #(parameter L=5, H=12) (
    input clk, rst_n,
    output reg clk_out
);
reg [7:0] cnt;
always @(posedge clk) begin
    if(!rst_n) begin
        cnt <= 0;
        clk_out <= 0;
    end else begin
        cnt <= cnt + 1;
        clk_out <= (cnt >= L) & (cnt <= H);
    end
end
endmodule
