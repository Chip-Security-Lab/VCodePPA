module PartialProduct(
    input [3:0] a, b,
    output [7:0] result
);
    wire [7:0] pp0 = b[0] ? {4'b0, a} : 0;
    wire [7:0] pp1 = b[1] ? {3'b0, a, 1'b0} : 0;
    wire [7:0] pp2 = b[2] ? {2'b0, a, 2'b0} : 0;
    wire [7:0] pp3 = b[3] ? {1'b0, a, 3'b0} : 0;
    
    assign result = pp0 + pp1 + pp2 + pp3;
endmodule