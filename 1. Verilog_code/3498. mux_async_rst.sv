module mux_async_rst #(parameter WIDTH=8)(
    input wire rst,
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output reg [WIDTH-1:0] data_out
);
always @(*) begin
    if (rst)
        data_out = 0;
    else
        data_out = sel ? data_a : data_b;
end
endmodule
