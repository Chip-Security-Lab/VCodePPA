module dither_pwm #(parameter N=8)(
    input clk, 
    input [N-1:0] din,
    output reg pwm
);
reg [N:0] err;
always @(posedge clk) begin
    {pwm, err} <= din + err[N-1:0];
end
endmodule
