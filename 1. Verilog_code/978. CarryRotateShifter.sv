module CarryRotateShifter #(parameter WIDTH=8) (
    input clk, en, carry_in,
    output reg carry_out,
    output reg [WIDTH-1:0] data_out
);
always @(posedge clk) begin
    if (en) {carry_out, data_out} <= {data_out, carry_in};
end
endmodule