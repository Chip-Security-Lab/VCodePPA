module parametric_adder #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,b,
    output [WIDTH-1:0] sum,
    output cout
);
    assign {cout,sum} = a + b;
endmodule