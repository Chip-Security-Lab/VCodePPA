//SystemVerilog
module shift_multiphase #(parameter WIDTH=8) (
    input clk0, clk1,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
reg [WIDTH-1:0] din_reg;

always @(posedge clk0) begin
    din_reg <= din;
end

always @(posedge clk1) begin
    dout <= din_reg << 2;
end

endmodule