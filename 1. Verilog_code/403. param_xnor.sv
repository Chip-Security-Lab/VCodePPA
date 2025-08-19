module param_xnor #(parameter WIDTH=8) (A, B, Y);
    input wire [WIDTH-1:0] A, B;
    output wire [WIDTH-1:0] Y;

    assign Y = ~(A ^ B);
endmodule