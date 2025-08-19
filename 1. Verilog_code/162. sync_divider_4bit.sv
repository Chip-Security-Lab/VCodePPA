module sync_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            quotient <= 0;
        else
            quotient <= a / b;
    end
endmodule
