module mixed_precision_mult (
    input [7:0] A,
    input [3:0] B,
    output [11:0] Result
);
    assign Result = A * B;
endmodule
