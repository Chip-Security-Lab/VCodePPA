//SystemVerilog
module uart_codec #(parameter DWIDTH = 8, parameter BAUD_DIV = 16)
(
    input wire clk, rst_n, tx_valid, rx_in,
    input wire [DWIDTH-1:0] tx_data,
    output reg rx_valid, tx_out,
    output reg [DWIDTH-1:0] rx_data
);
    // 状态定义
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    // TX 流水线阶段信号
    reg [1:0] tx_state_stage1, tx_state_stage2;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt_stage1, tx_bit_cnt_stage2;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt_stage1, tx_baud_cnt_stage2;
    reg [DWIDTH-1:0] tx_shift_reg_stage1, tx_shift_reg_stage2;
    reg tx_valid_stage1, tx_valid_stage2;
    reg tx_out_stage1;
    
    // 流水线控制信号
    reg pipeline_valid_stage1, pipeline_valid_stage2;
    
    // TX 第一级流水线重置逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_stage1 <= IDLE;
            tx_bit_cnt_stage1 <= 0;
            tx_baud_cnt_stage1 <= 0;
            tx_shift_reg_stage1 <= 0;
            tx_valid_stage1 <= 1'b0;
            pipeline_valid_stage1 <= 1'b0;
        end else begin
            pipeline_valid_stage1 <= 1'b1;
            tx_valid_stage1 <= tx_valid;
        end
    end
    
    // TX 第一级流水线：IDLE状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (tx_state_stage1 == IDLE) begin
            if (tx_valid) begin
                tx_state_stage1 <= START;
                tx_shift_reg_stage1 <= tx_data;
                tx_baud_cnt_stage1 <= 0;
            end
        end
    end
    
    // TX 第一级流水线：START状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (tx_state_stage1 == START) begin
            if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                tx_state_stage1 <= DATA;
                tx_baud_cnt_stage1 <= 0;
                tx_bit_cnt_stage1 <= 0;
            end else begin
                tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // TX 第一级流水线：DATA状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (tx_state_stage1 == DATA) begin
            if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                tx_baud_cnt_stage1 <= 0;
                
                if (tx_bit_cnt_stage1 == DWIDTH-1) begin
                    tx_state_stage1 <= STOP;
                end else begin
                    tx_bit_cnt_stage1 <= tx_bit_cnt_stage1 + 1;
                end
                
                // 预处理移位寄存器以供下一级流水线使用
                tx_shift_reg_stage1 <= tx_shift_reg_stage1 >> 1;
            end else begin
                tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // TX 第一级流水线：STOP状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (tx_state_stage1 == STOP) begin
            if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                tx_state_stage1 <= IDLE;
                tx_baud_cnt_stage1 <= 0;
            end else begin
                tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // TX 第一级流水线：默认状态处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (tx_state_stage1 > STOP) begin
            tx_state_stage1 <= IDLE;
        end
    end
    
    // TX 第二级流水线：重置和数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_stage2 <= IDLE;
            tx_bit_cnt_stage2 <= 0;
            tx_baud_cnt_stage2 <= 0;
            tx_shift_reg_stage2 <= 0;
            tx_valid_stage2 <= 1'b0;
            pipeline_valid_stage2 <= 1'b0;
        end else if (pipeline_valid_stage1) begin
            // 传递第一级流水线数据到第二级
            tx_state_stage2 <= tx_state_stage1;
            tx_bit_cnt_stage2 <= tx_bit_cnt_stage1;
            tx_baud_cnt_stage2 <= tx_baud_cnt_stage1;
            tx_shift_reg_stage2 <= tx_shift_reg_stage1;
            tx_valid_stage2 <= tx_valid_stage1;
            pipeline_valid_stage2 <= pipeline_valid_stage1;
        end
    end
    
    // TX 第二级流水线：输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out <= 1'b1;
        end else if (pipeline_valid_stage1) begin
            case (tx_state_stage1)
                IDLE:   tx_out <= 1'b1;
                START:  tx_out <= 1'b0; // 起始位
                DATA:   begin
                    if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                        tx_out <= tx_shift_reg_stage1[0];
                    end
                end
                STOP:   tx_out <= 1'b1; // 停止位
                default: tx_out <= 1'b1;
            endcase
        end
    end
    
    // RX 流水线阶段信号
    reg [1:0] rx_state_stage1, rx_state_stage2, rx_state_stage3;
    reg [$clog2(DWIDTH)-1:0] rx_bit_cnt_stage1, rx_bit_cnt_stage2, rx_bit_cnt_stage3;
    reg [$clog2(BAUD_DIV)-1:0] rx_baud_cnt_stage1, rx_baud_cnt_stage2, rx_baud_cnt_stage3;
    reg [DWIDTH-1:0] rx_shift_reg_stage1, rx_shift_reg_stage2, rx_shift_reg_stage3;
    reg rx_in_stage1, rx_in_stage2, rx_in_stage3;
    reg rx_valid_stage1, rx_valid_stage2, rx_valid_stage3;
    
    // RX 流水线控制信号
    reg rx_pipeline_valid_stage1, rx_pipeline_valid_stage2, rx_pipeline_valid_stage3;
    
    // RX 第一级流水线：重置逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_stage1 <= IDLE;
            rx_bit_cnt_stage1 <= 0;
            rx_baud_cnt_stage1 <= 0;
            rx_shift_reg_stage1 <= 0;
            rx_in_stage1 <= 1'b1;
            rx_valid_stage1 <= 1'b0;
            rx_pipeline_valid_stage1 <= 1'b0;
        end else begin
            rx_pipeline_valid_stage1 <= 1'b1;
            rx_in_stage1 <= rx_in;
        end
    end
    
    // RX 第一级流水线：IDLE状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (rx_state_stage1 == IDLE) begin
            rx_valid_stage1 <= 1'b0;
            // 检测起始位
            if (rx_in == 1'b0) begin
                rx_state_stage1 <= START;
                rx_baud_cnt_stage1 <= 0;
            end
        end
    end
    
    // RX 第一级流水线：START状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (rx_state_stage1 == START) begin
            // 等待半个波特周期进行采样点校准
            if (rx_baud_cnt_stage1 == (BAUD_DIV/2)-1) begin
                if (rx_in == 1'b0) begin // 确认起始位
                    rx_state_stage1 <= DATA;
                    rx_baud_cnt_stage1 <= 0;
                    rx_bit_cnt_stage1 <= 0;
                    rx_shift_reg_stage1 <= 0;
                end else begin
                    rx_state_stage1 <= IDLE; // 错误的起始位
                end
            end else begin
                rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // RX 第一级流水线：DATA状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (rx_state_stage1 == DATA) begin
            if (rx_baud_cnt_stage1 == BAUD_DIV-1) begin
                rx_baud_cnt_stage1 <= 0;
                
                // 数据采样
                rx_shift_reg_stage1 <= {rx_in, rx_shift_reg_stage1[DWIDTH-1:1]};
                
                if (rx_bit_cnt_stage1 == DWIDTH-1) begin
                    rx_state_stage1 <= STOP;
                end else begin
                    rx_bit_cnt_stage1 <= rx_bit_cnt_stage1 + 1;
                end
            end else begin
                rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // RX 第一级流水线：STOP状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (rx_state_stage1 == STOP) begin
            if (rx_baud_cnt_stage1 == BAUD_DIV-1) begin
                rx_state_stage1 <= IDLE;
                if (rx_in == 1'b1) begin // 有效停止位
                    rx_valid_stage1 <= 1'b1;
                end
            end else begin
                rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
            end
        end
    end
    
    // RX 第一级流水线：默认状态处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置已在上面的always块中处理
        end else if (rx_state_stage1 > STOP) begin
            rx_state_stage1 <= IDLE;
        end
    end
    
    // RX 第二级流水线：数据处理和状态传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_stage2 <= IDLE;
            rx_bit_cnt_stage2 <= 0;
            rx_baud_cnt_stage2 <= 0;
            rx_shift_reg_stage2 <= 0;
            rx_in_stage2 <= 1'b1;
            rx_valid_stage2 <= 1'b0;
            rx_pipeline_valid_stage2 <= 1'b0;
        end else if (rx_pipeline_valid_stage1) begin
            // 传递第一级数据到第二级
            rx_state_stage2 <= rx_state_stage1;
            rx_bit_cnt_stage2 <= rx_bit_cnt_stage1;
            rx_baud_cnt_stage2 <= rx_baud_cnt_stage1;
            rx_shift_reg_stage2 <= rx_shift_reg_stage1;
            rx_in_stage2 <= rx_in_stage1;
            rx_valid_stage2 <= rx_valid_stage1;
            rx_pipeline_valid_stage2 <= rx_pipeline_valid_stage1;
        end
    end
    
    // RX 第三级流水线：输出有效信号生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_pipeline_valid_stage3 <= 1'b0;
        end else if (rx_pipeline_valid_stage2) begin
            rx_valid <= rx_valid_stage2;
            rx_pipeline_valid_stage3 <= rx_pipeline_valid_stage2;
        end
    end
    
    // RX 第三级流水线：输出数据生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
        end else if (rx_pipeline_valid_stage2 && rx_valid_stage2) begin
            rx_data <= rx_shift_reg_stage2;
        end
    end
    
endmodule