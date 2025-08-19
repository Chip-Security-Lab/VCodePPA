module loadable_div #(parameter W=4) (
    input clk, load, 
    input [W-1:0] div_val,
    output reg clk_out
);
reg [W-1:0] cnt;
always @(posedge clk) begin
    if(load) begin
        cnt <= div_val;
        clk_out <= 1'b1;
    end else begin
        cnt <= (cnt == 0) ? div_val : cnt - 1;
        clk_out <= (cnt != 0);
    end
end
endmodule
