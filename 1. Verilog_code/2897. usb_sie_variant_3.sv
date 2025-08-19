//SystemVerilog
module usb_sie(
    input clk, reset_n,
    input [7:0] rx_data,
    input rx_valid,
    output reg rx_ready,
    output reg [7:0] tx_data,
    output reg tx_valid,
    input tx_ready,
    output reg [1:0] state
);
    localparam IDLE = 2'b00, RX = 2'b01, PROCESS = 2'b10, TX = 2'b11;
    
    // 增加流水线级数
    reg [7:0] rx_data_stage1, rx_data_stage2;
    reg rx_valid_stage1, rx_valid_stage2;
    reg [7:0] buffer_stage1, buffer_stage2, buffer_stage3;
    reg [1:0] state_stage1, state_stage2;
    
    // 处理阶段标志
    reg process_start_stage1, process_start_stage2, process_start_stage3;
    reg process_done_stage1, process_done_stage2, process_done_stage3;
    
    // 重置信号的缓冲寄存器（降低扇出）
    reg reset_n_buf1, reset_n_buf2, reset_n_buf3, reset_n_buf4;
    
    // 为高扇出信号添加缓冲
    always @(posedge clk) begin
        reset_n_buf1 <= reset_n;
        reset_n_buf2 <= reset_n_buf1;
        reset_n_buf3 <= reset_n_buf1;
        reset_n_buf4 <= reset_n_buf2;
    end
    
    // 第一级流水线: 寄存输入信号
    always @(posedge clk or negedge reset_n_buf1) begin
        if (!reset_n_buf1) begin
            rx_data_stage1 <= 8'h00;
            rx_valid_stage1 <= 1'b0;
        end else begin
            rx_data_stage1 <= rx_data;
            rx_valid_stage1 <= rx_valid;
        end
    end
    
    // 第二级流水线: 对输入数据再次寄存
    always @(posedge clk or negedge reset_n_buf2) begin
        if (!reset_n_buf2) begin
            rx_data_stage2 <= 8'h00;
            rx_valid_stage2 <= 1'b0;
        end else begin
            rx_data_stage2 <= rx_data_stage1;
            rx_valid_stage2 <= rx_valid_stage1;
        end
    end
    
    // 状态控制流水线 - 分为多个阶段
    always @(posedge clk or negedge reset_n_buf3) begin
        if (!reset_n_buf3) begin
            state <= IDLE;
            state_stage1 <= IDLE;
            state_stage2 <= IDLE;
            rx_ready <= 1'b0;
            process_start_stage1 <= 1'b0;
            process_start_stage2 <= 1'b0;
            process_start_stage3 <= 1'b0;
        end else begin
            // 状态流水线传递
            state <= state_stage2;
            state_stage2 <= state_stage1;
            
            // 处理启动信号流水线传递
            process_start_stage3 <= process_start_stage2;
            process_start_stage2 <= process_start_stage1;
            
            case (state)
                IDLE: begin
                    if (rx_valid_stage2) begin
                        rx_ready <= 1'b1;
                        state_stage1 <= RX;
                    end else begin
                        state_stage1 <= IDLE;
                    end
                    process_start_stage1 <= 1'b0;
                end
                
                RX: begin
                    rx_ready <= 1'b0;
                    state_stage1 <= PROCESS;
                    process_start_stage1 <= 1'b1;
                end
                
                PROCESS: begin
                    process_start_stage1 <= 1'b0;
                    if (process_done_stage3) begin
                        state_stage1 <= TX;
                    end else begin
                        state_stage1 <= PROCESS;
                    end
                end
                
                TX: begin
                    if (tx_ready) begin
                        state_stage1 <= IDLE;
                    end else begin
                        state_stage1 <= TX;
                    end
                end
            endcase
        end
    end
    
    // 数据缓存流水线
    always @(posedge clk or negedge reset_n_buf2) begin
        if (!reset_n_buf2) begin
            buffer_stage1 <= 8'h00;
            buffer_stage2 <= 8'h00;
            buffer_stage3 <= 8'h00;
        end else begin
            // 接收数据时，捕获数据到第一级缓存
            if (state == RX) begin
                buffer_stage1 <= rx_data_stage2;
            end
            
            // 处理流水线
            if (process_start_stage1) begin
                // 数据开始进入处理流水线
                buffer_stage2 <= buffer_stage1; // 第一级处理
            end
            
            if (process_start_stage2) begin
                // 数据继续向后流水
                buffer_stage3 <= buffer_stage2; // 第二级处理
            end
        end
    end
    
    // 处理完成状态流水线
    always @(posedge clk or negedge reset_n_buf3) begin
        if (!reset_n_buf3) begin
            process_done_stage1 <= 1'b0;
            process_done_stage2 <= 1'b0;
            process_done_stage3 <= 1'b0;
        end else begin
            process_done_stage1 <= process_start_stage1;
            process_done_stage2 <= process_done_stage1;
            process_done_stage3 <= process_done_stage2;
        end
    end
    
    // 发送逻辑流水线 - 使用单独的重置缓冲
    always @(posedge clk or negedge reset_n_buf4) begin
        if (!reset_n_buf4) begin
            tx_valid <= 1'b0;
            tx_data <= 8'h00;
        end else begin
            case (state)
                PROCESS: begin
                    if (process_done_stage3) begin
                        tx_data <= buffer_stage3;
                        tx_valid <= 1'b1;
                    end
                end
                
                TX: begin
                    if (tx_ready) begin
                        tx_valid <= 1'b0;
                    end
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
endmodule