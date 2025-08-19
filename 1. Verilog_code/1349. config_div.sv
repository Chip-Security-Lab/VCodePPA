module config_div #(parameter MODE=0) (
    input clk, rst,
    output reg clk_out
);
localparam DIV = (MODE) ? 8 : 16;
reg [4:0] cnt;
always @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
        clk_out <= 0;
    end else if(cnt == DIV-1) begin
        cnt <= 0;
        clk_out <= ~clk_out;
    end else cnt <= cnt + 1;
end
endmodule
