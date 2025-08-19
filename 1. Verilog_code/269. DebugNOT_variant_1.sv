//SystemVerilog
module DebugNOT(
    input [7:0] data,
    output [7:0] inverse,
    output parity
);
    // 使用单独的wire进行位翻转，可以改善布线和时序
    wire [7:0] inverse_temp;
    
    // 将位运算拆分以减少逻辑深度，使用展开的结构代替for循环
    assign inverse_temp[0] = !data[0];
    assign inverse_temp[1] = !data[1];
    assign inverse_temp[2] = !data[2];
    assign inverse_temp[3] = !data[3];
    assign inverse_temp[4] = !data[4];
    assign inverse_temp[5] = !data[5];
    assign inverse_temp[6] = !data[6];
    assign inverse_temp[7] = !data[7];
    
    // 寄存输出以提高时序性能
    reg [7:0] inverse_reg;
    reg parity_reg;
    
    always @(*) begin
        inverse_reg = inverse_temp;
        // 使用优化的奇偶校验计算
        parity_reg = inverse_temp[0] ^ inverse_temp[1] ^ 
                    inverse_temp[2] ^ inverse_temp[3] ^
                    inverse_temp[4] ^ inverse_temp[5] ^
                    inverse_temp[6] ^ inverse_temp[7];
    end
    
    // 输出赋值
    assign inverse = inverse_reg;
    assign parity = parity_reg;
    
endmodule