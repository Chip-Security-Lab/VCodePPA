module multiplier_4bit_shift (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    reg [7:0] result;
    integer i;
    always @(a, b) begin
        result = 0;
        for (i = 0; i < 4; i = i + 1) begin
            if (b[i]) result = result + (a << i);
        end
    end
    assign product = result;
endmodule
