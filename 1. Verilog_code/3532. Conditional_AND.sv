module Conditional_AND(
    input sel,
    input [7:0] op_a, op_b,
    output [7:0] res
);
    assign res = sel ? (op_a & op_b) : 8'hFF; 
endmodule
