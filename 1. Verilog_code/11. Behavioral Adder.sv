module behavioral_adder(
    input [7:0] a,b,
    output reg [7:0] sum,
    output reg cout
);
    always @(*) {cout,sum} = a + b;
endmodule