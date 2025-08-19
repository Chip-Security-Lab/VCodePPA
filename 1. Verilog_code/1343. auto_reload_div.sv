module auto_reload_div #(parameter DIV=6) (
    input clk, en,
    output reg clk_out
);
reg [3:0] cnt;
always @(posedge clk) begin
    if(!en) {cnt,clk_out} <= 0;
    else if(cnt == DIV-1) begin
        cnt <= 0;
        clk_out <= ~clk_out;
    end else cnt <= cnt + 1;
end
endmodule
