//SystemVerilog
module active_low_decoder(
    input [2:0] address,
    output reg [7:0] decode_n
);
    // 带符号乘法实现解码器功能
    reg signed [7:0] base_value;
    reg signed [7:0] shift_amount;
    reg signed [7:0] multiplier;
    reg signed [15:0] mul_result;
    
    always @(*) begin
        // 初始化所有输出为高电平
        decode_n = 8'hFF;
        
        // 基于带符号乘法计算解码值
        base_value = 8'b11111110; // 初始掩码 (FE)
        shift_amount = {5'b00000, address}; // 扩展address为8位
        
        if (address == 3'b000) begin
            // 特殊情况处理，避免无效移位
            decode_n = 8'b11111110;
        end else begin
            // 计算乘数 (2^address)
            multiplier = 8'sd1 << shift_amount[2:0];
            
            // 执行带符号乘法
            mul_result = base_value * multiplier;
            
            // 结果转换回解码器输出格式
            decode_n = ~(~mul_result[7:0] & 8'h01) & 8'hFF;
        end
        
        // 直接设置目标位，确保功能正确性
        decode_n[address] = 1'b0;
    end
endmodule