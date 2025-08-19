//SystemVerilog
module usb_nrzi_encoder (
    input wire clk,         // 系统时钟
    input wire en,          // 使能信号
    input wire data,        // 输入数据
    output reg tx           // 输出NRZI编码数据
);
    // 数据流水线寄存器
    reg stage1_data;        // 第一级流水线寄存器，保存输入数据
    reg stage1_valid;       // 数据有效标志
    reg nrzi_state;         // NRZI状态寄存器
    
    // 为高扇出信号添加缓冲寄存器
    reg nrzi_state_buf;     // 单级nrzi_state缓冲寄存器
    
    // 第一级：数据捕获和有效性检查 - 优化逻辑
    always @(posedge clk) begin
        stage1_data <= data;
        stage1_valid <= en;
    end

    // 第二级：NRZI编码逻辑 - 布尔表达式优化
    always @(posedge clk) begin
        if (stage1_valid) begin
            // 优化表达式: nrzi_state <= stage1_data ? nrzi_state : ~nrzi_state
            // 等效于: nrzi_state <= nrzi_state ^ ~stage1_data
            nrzi_state <= nrzi_state ^ ~stage1_data;
        end
    end
    
    // 单级缓冲更高效，减少不必要的延迟和功耗
    always @(posedge clk) begin
        nrzi_state_buf <= nrzi_state;
    end

    // 输出驱动逻辑 - 使用单级缓冲以减少延迟
    always @(posedge clk) begin
        if (stage1_valid) begin
            tx <= nrzi_state_buf;
        end
    end

endmodule