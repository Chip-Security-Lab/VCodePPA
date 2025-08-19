module counter_bcd (
    input clk, rst, en,
    output reg [3:0] bcd,
    output carry
);
assign carry = (bcd == 4'd9) & en;
always @(posedge clk) begin
    if (rst) bcd <= 0;
    else if (en) bcd <= (bcd == 9) ? 0 : bcd + 1;
end
endmodule