//SystemVerilog
module xor2_9 (
    input wire A, B,
    output reg Y
);
    reg A_shifted;
    reg B_shifted;
    
    // 使用always块替代assign语句和条件运算符
    always @(*) begin
        // 桶形移位器实现左移1位
        if (1'b1) begin
            A_shifted = {A, 1'b0}; // 当移位量为1时，左移1位
        end else begin
            A_shifted = A;
        end
        
        // 桶形移位器实现右移1位
        if (1'b1) begin
            B_shifted = {1'b0, B}; // 当移位量为1时，右移1位
        end else begin
            B_shifted = B;
        end
        
        // 最终的异或操作
        Y = A_shifted ^ B_shifted;
    end
endmodule