//SystemVerilog
module PartialProduct(
    input [3:0] a, b,
    output [7:0] result
);
    // Partial products generation with optimized shift
    wire [7:0] pp0 = {4'b0, a & {4{b[0]}}};
    wire [7:0] pp1 = {3'b0, a & {4{b[1]}}, 1'b0};
    wire [7:0] pp2 = {2'b0, a & {4{b[2]}}, 2'b0};
    wire [7:0] pp3 = {1'b0, a & {4{b[3]}}, 3'b0};
    
    // Optimized carry-save addition
    wire [7:0] sum1, carry1;
    wire [7:0] sum2, carry2;
    wire [7:0] sum3, carry3;
    
    // First stage: pp0 + pp1
    assign {carry1, sum1} = pp0 + pp1;
    
    // Second stage: (pp0+pp1) + pp2
    assign {carry2, sum2} = sum1 + pp2 + carry1;
    
    // Final stage: (pp0+pp1+pp2) + pp3
    assign {carry3, result} = sum2 + pp3 + carry2;
endmodule