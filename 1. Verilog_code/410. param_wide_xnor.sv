module param_wide_xnor #(parameter WIDTH=16) (A, B, Y);
    input [WIDTH-1:0] A, B;
    output reg [WIDTH-1:0] Y;

    integer i;

    always @(*) begin
        Y = ~(A ^ B);
    end
endmodule