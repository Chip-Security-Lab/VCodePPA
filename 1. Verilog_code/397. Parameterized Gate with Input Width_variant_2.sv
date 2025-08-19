//SystemVerilog
module nand2_17 #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // 内部借位信号
    wire [WIDTH:0] borrow;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 先行借位减法器实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            // 产生借位 - 当A<B或(A=B且有借入)时产生借位
            assign borrow[i+1] = (~A[i] & B[i]) | ((~A[i] | B[i]) & borrow[i]);
            
            // 计算差值 - 异或操作后考虑借位
            assign Y[i] = A[i] ^ B[i] ^ borrow[i];
        end
    endgenerate
endmodule