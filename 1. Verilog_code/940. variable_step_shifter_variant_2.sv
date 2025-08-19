//SystemVerilog
module variable_step_shifter (
    input [15:0] din,
    input [1:0] step_mode,  // 00:+1, 01:+2, 10:+4
    output [15:0] dout
);
    // 内部信号定义
    reg [15:0] shifted_result;
    reg [3:0] shift_amount;
    reg [15:0] left_shifted, right_shifted;
    
    // 使用二进制补码算法确定移位量
    always @(*) begin
        case(step_mode)
            2'b00: shift_amount = 4'd1;
            2'b01: shift_amount = 4'd2;
            2'b10: shift_amount = 4'd4;
            default: shift_amount = 4'd1;
        endcase
        
        // 左移和右移计算
        left_shifted = din << shift_amount;
        
        // 使用补码减法计算(16-shift)
        // 16的补码表示为10000，对shift取反加1
        right_shifted = din >> (~shift_amount + 4'b1 + 4'b10000);
        
        // 合并结果
        shifted_result = left_shifted | right_shifted;
    end
    
    // 输出赋值
    assign dout = shifted_result;
endmodule