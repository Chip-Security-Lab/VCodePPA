module divider_with_counter (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [3:0] cycle_count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            cycle_count <= 0;
        end else begin
            if (cycle_count < 8) begin
                quotient <= a / b;
                remainder <= a % b;
                cycle_count <= cycle_count + 1;
            end
        end
    end
endmodule
