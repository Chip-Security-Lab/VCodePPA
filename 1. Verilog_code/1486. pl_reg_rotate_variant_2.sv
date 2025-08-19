//SystemVerilog
`timescale 1ns / 1ps
module pl_reg_rotate #(parameter W=8) (
    input clk, load, rotate,
    input [W-1:0] d_in,
    output reg [W-1:0] q
);
    // 借位减法器信号
    wire [W:0] borrow;        // 借位信号，多一位
    wire [W-1:0] minuend;     // 被减数
    wire [W-1:0] subtrahend;  // 减数
    wire [W-1:0] diff;        // 差值结果
    
    // 确定被减数和减数
    assign minuend = q;
    
    // 实现循环减法，减数为循环右移一位
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin: gen_subtrahend
            assign subtrahend[i] = (i == 0) ? q[W-1] : q[i-1];
        end
    endgenerate
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;  // 初始借位为0
    
    generate
        for (i = 0; i < W; i = i + 1) begin: gen_difference
            // 差值计算
            assign diff[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            // 借位生成逻辑
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                               (~minuend[i] & borrow[i]) | 
                               (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (load)
            q <= d_in;
        else if (rotate)
            q <= {q[W-2:0], q[W-1]};
        else
            q <= diff;  // 使用借位减法器计算结果
    end
endmodule