module multi_cycle_divider (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [3:0] count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            count <= 0;
        end else if (count < 8) begin
            dividend <= a;
            divisor <= b;
            quotient <= dividend / divisor;
            remainder <= dividend % divisor;
            count <= count + 1;
        end
    end
endmodule
