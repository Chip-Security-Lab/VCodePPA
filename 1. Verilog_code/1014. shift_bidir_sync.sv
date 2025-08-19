module shift_bidir_sync #(parameter WIDTH=16) (
    input clk, rst,
    input dir,  // 0:left, 1:right
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk or posedge rst) begin
    if(rst) dout <= 0;
    else dout <= dir ? (din >> 1) : (din << 1);
end
endmodule