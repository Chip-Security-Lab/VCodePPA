module adder_9 #(parameter WIDTH = 1) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
  );
  assign sum = a + b;
endmodule