//SystemVerilog
module mixed_precision_mult (
    input [7:0] A,
    input [3:0] B,
    output [11:0] Result
);

    // Partial products generation
    wire [7:0] pp0, pp1, pp2, pp3;
    assign pp0 = A & {8{B[0]}};
    assign pp1 = (A & {8{B[1]}}) << 1;
    assign pp2 = (A & {8{B[2]}}) << 2;
    assign pp3 = (A & {8{B[3]}}) << 3;

    // First level of reduction
    wire [8:0] sum1, carry1;
    wire [9:0] sum2, carry2;
    
    // First CSA
    assign {carry1, sum1} = pp0 + pp1 + pp2;
    
    // Second CSA
    assign {carry2, sum2} = sum1 + carry1 + pp3;

    // Final addition
    assign Result = sum2 + carry2;

endmodule