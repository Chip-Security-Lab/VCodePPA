module shift_multiphase #(parameter WIDTH=8) (
    input clk0, clk1,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
reg [WIDTH-1:0] phase_reg;
always @(posedge clk0) phase_reg <= din;
always @(posedge clk1) dout <= phase_reg << 2;
endmodule
