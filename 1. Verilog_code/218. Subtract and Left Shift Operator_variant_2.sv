//SystemVerilog
module subtract_shift_left (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] difference,
    output [7:0] shifted_result
);
    // 使用先行借位减法器实现减法
    wire [8:0] borrow;  // 借位信号，包括初始借位(borrow[0])
    wire [7:0] diff;    // 差值
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 生成每一位的借位和差值
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_borrow
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
            assign borrow[i+1] = (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i]);
        end
    endgenerate
    
    // 最终差值输出
    assign difference = diff;
    
    // 左移操作保持不变
    assign shifted_result = a << shift_amount;
endmodule