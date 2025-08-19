//SystemVerilog
module SignExtendShifter #(parameter WIDTH=8) (
    input clk, arith_shift,
    input signed [WIDTH-1:0] data_in,
    output reg signed [WIDTH-1:0] data_out
);
always @(posedge clk) begin
    data_out <= arith_shift ? data_in >>> 1 : data_in << 1;
end
endmodule