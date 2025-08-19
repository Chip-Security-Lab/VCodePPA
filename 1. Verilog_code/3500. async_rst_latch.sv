module async_rst_latch #(parameter WIDTH=8)(
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] latch_out
);
always @(*) begin
    if (rst)
        latch_out = {WIDTH{1'b0}};
    else if (en)
        latch_out = din;
end
endmodule
