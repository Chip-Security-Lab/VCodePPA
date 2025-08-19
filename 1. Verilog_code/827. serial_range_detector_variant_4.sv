//SystemVerilog
module serial_range_detector(
    input wire clk, rst, data_bit, valid,
    input wire [7:0] lower, upper,
    output reg in_range
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg [7:0] lower_reg, upper_reg;
    reg byte_complete;
    
    // 将比较逻辑提前，移除中间寄存器
    wire [7:0] next_shift_reg = {shift_reg[6:0], data_bit};
    wire next_byte_complete = (bit_count == 3'b111);
    
    // 使用先行进位加法器进行比较运算
    wire [7:0] cmp_low_result;
    wire [7:0] cmp_high_result;
    wire cmp_low_carry;
    wire cmp_high_carry;
    
    // 生成和传播信号 - 低边界比较
    wire [7:0] g_low, p_low;
    wire [8:0] c_low;
    
    // 生成和传播信号 - 高边界比较
    wire [7:0] g_high, p_high;
    wire [8:0] c_high;
    
    // 低边界比较的先行进位加法器实现
    assign g_low = next_shift_reg & (~lower);
    assign p_low = next_shift_reg | (~lower);
    assign c_low[0] = 1'b1; // 初始进位设为1，用于>=比较
    
    // 高边界比较的先行进位加法器实现
    assign g_high = (~next_shift_reg) & upper;
    assign p_high = (~next_shift_reg) | upper;
    assign c_high[0] = 1'b1; // 初始进位设为1，用于<=比较
    
    // 先行进位生成 - 低边界
    assign c_low[1] = g_low[0] | (p_low[0] & c_low[0]);
    assign c_low[2] = g_low[1] | (p_low[1] & g_low[0]) | (p_low[1] & p_low[0] & c_low[0]);
    assign c_low[3] = g_low[2] | (p_low[2] & g_low[1]) | (p_low[2] & p_low[1] & g_low[0]) | (p_low[2] & p_low[1] & p_low[0] & c_low[0]);
    assign c_low[4] = g_low[3] | (p_low[3] & g_low[2]) | (p_low[3] & p_low[2] & g_low[1]) | (p_low[3] & p_low[2] & p_low[1] & g_low[0]) | (p_low[3] & p_low[2] & p_low[1] & p_low[0] & c_low[0]);
    assign c_low[5] = g_low[4] | (p_low[4] & c_low[4]);
    assign c_low[6] = g_low[5] | (p_low[5] & c_low[5]);
    assign c_low[7] = g_low[6] | (p_low[6] & c_low[6]);
    assign c_low[8] = g_low[7] | (p_low[7] & c_low[7]);
    
    // 先行进位生成 - 高边界
    assign c_high[1] = g_high[0] | (p_high[0] & c_high[0]);
    assign c_high[2] = g_high[1] | (p_high[1] & g_high[0]) | (p_high[1] & p_high[0] & c_high[0]);
    assign c_high[3] = g_high[2] | (p_high[2] & g_high[1]) | (p_high[2] & p_high[1] & g_high[0]) | (p_high[2] & p_high[1] & p_high[0] & c_high[0]);
    assign c_high[4] = g_high[3] | (p_high[3] & g_high[2]) | (p_high[3] & p_high[2] & g_high[1]) | (p_high[3] & p_high[2] & p_high[1] & g_high[0]) | (p_high[3] & p_high[2] & p_high[1] & p_high[0] & c_high[0]);
    assign c_high[5] = g_high[4] | (p_high[4] & c_high[4]);
    assign c_high[6] = g_high[5] | (p_high[5] & c_high[5]);
    assign c_high[7] = g_high[6] | (p_high[6] & c_high[6]);
    assign c_high[8] = g_high[7] | (p_high[7] & c_high[7]);
    
    // 比较结果
    assign cmp_low = c_low[8];  // 输出进位表示 next_shift_reg >= lower
    assign cmp_high = c_high[8]; // 输出进位表示 next_shift_reg <= upper
    
    wire next_in_range = next_byte_complete && cmp_low && cmp_high;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 8'b0;
            bit_count <= 3'b0;
            lower_reg <= 8'b0;
            upper_reg <= 8'b0;
            byte_complete <= 1'b0;
            in_range <= 1'b0;
        end
        else if (valid) begin
            // 寄存器输入数据和范围边界
            shift_reg <= next_shift_reg;
            lower_reg <= lower;
            upper_reg <= upper;
            bit_count <= bit_count + 1;
            
            // 字节完成标志
            byte_complete <= next_byte_complete;
            
            // 直接将组合逻辑结果寄存到输出
            in_range <= next_in_range;
        end
    end
endmodule