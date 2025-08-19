module MuxAsyncEn #(parameter W=4, N=8) (
    input [N*W-1:0] bus_in,
    input [2:0] sel,
    input en,
    output reg [W-1:0] q,
    input rst
);
always @(*) begin
    if (rst) q = 0;
    else q = en ? bus_in[sel*W +: W] : q;
end
endmodule