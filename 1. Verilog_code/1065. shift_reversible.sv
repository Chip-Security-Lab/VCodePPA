module shift_reversible #(parameter WIDTH=8) (
    input clk, reverse,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk) begin
    dout <= reverse ? {din[0], din[WIDTH-1:1]} :
                    {din[WIDTH-2:0], din[WIDTH-1]};
end
endmodule
