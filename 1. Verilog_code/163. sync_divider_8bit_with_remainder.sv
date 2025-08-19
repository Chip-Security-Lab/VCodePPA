module sync_divider_8bit_with_remainder (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
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
