module tff_pulse (
    input clk, rstn, t,
    output reg q
);
always @(posedge clk) begin
    if (!rstn) q <= 0;
    else if (t) q <= ~q;
end
endmodule