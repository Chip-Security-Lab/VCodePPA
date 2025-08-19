//SystemVerilog
module sr_latch_enable (
    input wire enable,
    input wire s,
    input wire r,
    output reg q
);
    // 直接使用更简单的逻辑来实现同样的功能
    // 避免不必要的信号扩展和乘法运算
    wire set_q, reset_q;
    
    // 简化的状态判断逻辑
    assign set_q = s && !r;    // s=1,r=0时为真
    assign reset_q = !s && r;  // s=0,r=1时为真
    
    // 合并输出控制逻辑到单个always块，提高效率
    always @(*) begin
        if (enable) begin
            if (set_q)
                q <= 1'b1;
            else if (reset_q)
                q <= 1'b0;
            // 当s=r=1或s=r=0时保持原状态
        end
    end
endmodule