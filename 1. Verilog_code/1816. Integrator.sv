module Integrator #(parameter W=8, MAX=255) (
    input clk, rst,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W+1:0] accumulator;
    always @(posedge clk or posedge rst) begin
        if(rst) {accumulator, dout} <= 0;
        else begin
            accumulator <= accumulator + din;
            dout <= (accumulator > MAX) ? MAX : accumulator[W-1:0];
        end
    end
endmodule