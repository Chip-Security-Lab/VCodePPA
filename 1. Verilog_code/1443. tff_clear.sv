module tff_clear (
    input clk, clr,
    output reg q
);
always @(posedge clk) begin
    if (clr) q <= 0;
    else     q <= ~q;
end
endmodule