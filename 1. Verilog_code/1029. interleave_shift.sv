module interleave_shift #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
always @(posedge clk) begin
    dout <= {din[6], din[4], din[2], din[0],
             din[7], din[5], din[3], din[1]};
end
endmodule