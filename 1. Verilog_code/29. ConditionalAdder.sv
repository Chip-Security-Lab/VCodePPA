module Adder_7(
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum
);
    always @ (A or B) begin
        if (A[3:0] + B[3:0] > 15) 
            sum = A + B;
        else
            sum = A + B;
    end
endmodule
