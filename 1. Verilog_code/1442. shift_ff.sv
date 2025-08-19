module shift_ff (
    input clk, rstn, 
    input sin,
    output reg q
);
always @(posedge clk) begin
    if (!rstn) q <= 0;
    else       q <= sin;
end
endmodule