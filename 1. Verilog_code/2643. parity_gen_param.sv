module parity_gen_param #(
    parameter WIDTH = 32
)(
    input en,
    input [WIDTH-1:0] data,
    output reg parity
);
always @(*) begin
    if (en) parity = ^data;
    else parity = 1'b0;
end
endmodule