module shift_var_step #(parameter WIDTH=8) (
    input clk, rst,
    input [$clog2(WIDTH)-1:0] step,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk or posedge rst) begin
    if (rst) dout <= 0;
    else dout <= din << step;
end
endmodule
