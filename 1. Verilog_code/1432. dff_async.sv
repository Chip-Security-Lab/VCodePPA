module dff_async (
    input clk, arst_n,
    input d,
    output reg q
);
always @(posedge clk or negedge arst_n) begin
    if (!arst_n) q <= 1'b0;
    else         q <= d;
end
endmodule