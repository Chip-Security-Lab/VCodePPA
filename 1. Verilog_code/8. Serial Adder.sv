module serial_adder (
    input clk,
    input a, b,
    output reg sum
);
    reg carry;
    always @(posedge clk) begin
        {carry, sum} <= a + b + carry;
    end
endmodule