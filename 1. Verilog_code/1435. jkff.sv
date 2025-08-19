module jkff #(parameter W=1) (
    input clk, rstn,
    input [W-1:0] j, k,
    output reg [W-1:0] q
);
always @(posedge clk) begin
    if (!rstn) q <= 0;
    else case ({j,k})
        2'b10: q <= 1'b1;
        2'b01: q <= 1'b0;
        2'b11: q <= ~q;
    endcase
end
endmodule