//SystemVerilog
module sr_latch_enable (
    input wire enable,
    input wire s,
    input wire r,
    output reg q
);
    // 优化的比较逻辑，使用if-else级联结构替代case语句
    // 这提高了代码的可读性并改进了综合后的硬件结构
    always @(*) begin
        if (enable) begin
            if ({s, r} == 2'b10) begin
                q <= 1'b1;  // Set
            end
            else if ({s, r} == 2'b01) begin
                q <= 1'b0;  // Reset
            end
            // 其他情况保持输出不变（2'b00或2'b11）
        end
        // 当enable为0时保持输出不变
    end
endmodule