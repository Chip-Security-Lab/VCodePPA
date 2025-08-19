//SystemVerilog
module sync_signed_divider (
    input clk,
    input reset,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);
    always @(posedge clk or posedge reset) begin
        quotient <= reset ? 8'sb0 : a / b;
        remainder <= reset ? 8'sb0 : a % b;
    end
endmodule