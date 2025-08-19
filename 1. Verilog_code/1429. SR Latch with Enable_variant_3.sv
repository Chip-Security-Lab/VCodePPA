//SystemVerilog
module sr_latch_enable (
    input wire enable,
    input wire s,
    input wire r,
    output reg q
);
    // 合并处理置位和复位操作，减少always块数量
    // 优化比较链，避免多个条件检查
    always @(*) begin
        if (enable) begin
            case ({s, r})
                2'b10: q <= 1'b1;  // 置位
                2'b01: q <= 1'b0;  // 复位
                // 对于其他情况（2'b00或2'b11）保持原值
            endcase
        end
        // 当enable为0时保持原值
    end
endmodule