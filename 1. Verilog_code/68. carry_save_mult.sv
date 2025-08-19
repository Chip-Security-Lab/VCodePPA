module carry_save_mult (
    input [3:0] A, B,
    output [7:0] Prod
);
    wire [3:0] pp0 = {4{B[0]}} & A;
    wire [3:0] pp1 = {4{B[1]}} & A;
    wire [3:0] pp2 = {4{B[2]}} & A;
    wire [3:0] pp3 = {4{B[3]}} & A;
    
    // 进位保存加法器结构
    wire [7:0] sum = {4'b0, pp0} + {3'b0, pp1, 1'b0} + 
                    {2'b0, pp2, 2'b0} + {1'b0, pp3, 3'b0};
    assign Prod = sum;
endmodule
