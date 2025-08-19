module counter_updown #(parameter WIDTH=4) (
    input clk, rst, dir, en,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (rst) cnt <= 0;
    else if (en) cnt <= dir ? cnt + 1 : cnt - 1;
end
endmodule