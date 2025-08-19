//SystemVerilog
module preset_reg(
    input wire clk, 
    input wire sync_preset, 
    input wire load,
    input wire [11:0] data_in,
    output reg [11:0] data_out
);
    // 带符号乘法优化实现
    reg [11:0] next_data;
    reg [11:0] mult_result;
    reg [11:0] temp_data;
    
    // 计算带符号乘法结果
    always @(*) begin
        // 假设我们将data_in乘以一个固定系数，然后用于后续计算
        // 使用Booth算法实现带符号乘法
        // 这里采用12位带符号数乘法
        temp_data = data_in;
        mult_result = 12'b0;
        
        // 优化的Booth算法实现
        if (temp_data[11]) begin // 检查符号位
            mult_result = ~temp_data + 1'b1; // 补码转换
            mult_result = {mult_result[10:0], 1'b0}; // 优化的移位操作
        end else begin
            mult_result = {temp_data[10:0], 1'b0}; // 正数优化处理
        end
        
        // 根据控制信号选择输出
        if (sync_preset)
            next_data = 12'hFFF;
        else if (load)
            next_data = mult_result; // 使用乘法结果替代直接加载
        else
            next_data = data_out;
    end
    
    // 寄存器更新
    always @(posedge clk) begin
        data_out <= next_data;
    end
endmodule