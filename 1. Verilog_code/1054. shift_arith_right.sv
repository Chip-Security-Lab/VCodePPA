module shift_arith_right #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [2:0] shift_amount,
    output reg [WIDTH-1:0] data_out
);
always @* begin
    data_out = $signed(data_in) >>> shift_amount;
end
endmodule
