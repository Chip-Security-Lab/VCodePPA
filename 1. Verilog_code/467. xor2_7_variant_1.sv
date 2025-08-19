//SystemVerilog
module xor2_7 #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] A, B,
    output reg [WIDTH-1:0] Y
);
    // 使用条件反相减法器算法实现异或操作
    // X ^ Y 在数学上等价于 (X-Y)当Y=1时取反 或 (X+~Y+1)当Y=1时取反
    
    wire [WIDTH-1:0] not_B;
    wire [WIDTH-1:0] sum;
    reg [WIDTH-1:0] conditional_invert;
    
    // 生成B的取反
    assign not_B = ~B;
    
    // 计算A减B (使用A+~B+1)
    assign sum = A + not_B + 1'b1;
    
    // 使用always块和if-else语句替代条件运算符
    integer i;
    always @(*) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (B[i]) begin
                conditional_invert[i] = ~sum[i];
            end else begin
                conditional_invert[i] = sum[i];
            end
        end
        Y = conditional_invert;
    end
    
endmodule