//SystemVerilog
//IEEE 1364-2005 Verilog标准
module usb_nrzi_encoder(
    input  wire clk,       // 系统时钟
    input  wire reset,     // 系统复位，高电平有效
    input  wire data_in,   // 输入数据
    input  wire valid_in,  // 输入数据有效标志
    output reg  data_out,  // NRZI编码输出
    output reg  valid_out  // 输出数据有效标志
);

    // 状态寄存器
    reg last_bit;           // 保存上一个输出位的状态
    reg valid_pipeline;     // 流水线有效信号
    
    // 优化的NRZI编码实现
    // 使用更直接的逻辑判断，减少判断分支
    always @(posedge clk) begin
        if (reset) begin
            valid_pipeline <= 1'b0;
            valid_out <= 1'b0;
            data_out <= 1'b1;  // USB规范中，空闲状态为高电平
            last_bit <= 1'b1;
        end else begin
            // 第一级流水线
            valid_pipeline <= valid_in;
            
            // 第二级流水线（输出级）
            valid_out <= valid_pipeline;
            
            // 优化后的逻辑：使用三元操作符简化逻辑路径
            // 通过移除中间信号减少逻辑级数
            if (valid_pipeline) begin
                // 当data_in为0时翻转，为1时保持
                // 直接将数据位与翻转条件合并计算
                last_bit <= (data_in == 1'b0) ? ~last_bit : last_bit;
                data_out <= (data_in == 1'b0) ? ~last_bit : last_bit;
            end
        end
    end

endmodule