//SystemVerilog
module dither_pwm #(parameter N=8)(
    input clk, 
    input [N-1:0] din,
    output reg pwm
);
    reg [N:0] acc;
    
    always @(posedge clk) begin
        pwm <= (acc[N-1:0] < din) ? 1'b1 : 1'b0;
        acc <= (acc[N-1:0] < din) ? 
               {1'b0, acc[N-1:0]} + {1'b0, din} : 
               {1'b0, acc[N-1:0] - din};
    end
endmodule