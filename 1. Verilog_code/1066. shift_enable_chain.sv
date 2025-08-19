module shift_enable_chain #(parameter WIDTH=8) (
    input clk, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
reg [WIDTH-1:0] buffer;
always @(posedge clk) begin
    buffer <= en ? din : buffer;
    dout <= en ? {buffer[WIDTH-2:0], 1'b0} : dout;
end
endmodule
