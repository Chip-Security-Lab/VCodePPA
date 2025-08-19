module shift_cond_rst #(parameter WIDTH=8) (
    input clk, cond_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk) begin
    dout <= cond_rst ? din : {dout[WIDTH-2:0], din[WIDTH-1]};
end
endmodule
