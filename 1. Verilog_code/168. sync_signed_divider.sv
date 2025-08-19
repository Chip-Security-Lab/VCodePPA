module sync_signed_divider (
    input clk,
    input reset,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else begin
            quotient <= a / b;
            remainder <= a % b;
        end
    end
endmodule
