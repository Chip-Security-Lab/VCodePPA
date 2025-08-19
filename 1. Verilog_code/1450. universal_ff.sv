module universal_ff (
    input clk, rstn,
    input [1:0] mode,
    input d, j, k, t, s, r,
    output reg q
);
always @(posedge clk) begin
    if (!rstn) q <= 0;
    else case(mode)
        2'b00: q <= d;    // D模式
        2'b01: q <= j&~q | ~k&q; // JK模式
        2'b10: q <= t^q;  // T模式
        2'b11: q <= s | (~r & q); // SR模式
    endcase
end
endmodule