//SystemVerilog
module spi_codec #(parameter DATA_WIDTH = 8)
(
    input wire clk_i, rst_ni, enable_i,
    input wire [DATA_WIDTH-1:0] tx_data_i,
    input wire miso_i,
    output wire sclk_o, cs_no, mosi_o,
    output reg [DATA_WIDTH-1:0] rx_data_o,
    output reg tx_done_o, rx_done_o
);
    // Pipeline stage 1 - Input Registration
    reg enable_stage1;
    reg [DATA_WIDTH-1:0] tx_data_stage1;
    reg miso_stage1;
    
    // Pipeline stage 2 - Transaction Control
    reg spi_active_stage2;
    reg sclk_enable_stage2;
    reg [DATA_WIDTH-1:0] tx_shift_reg_stage2;
    reg [$clog2(DATA_WIDTH):0] bit_counter_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Data Shift and Capture
    reg spi_active_stage3;
    reg [DATA_WIDTH-1:0] tx_shift_reg_stage3;
    reg [DATA_WIDTH-1:0] rx_shift_reg_stage3;
    reg [$clog2(DATA_WIDTH):0] bit_counter_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 - Output Generation
    reg completion_flag_stage4;
    
    // 连续赋值 - 时钟和控制信号
    assign sclk_o = enable_stage1 & sclk_enable_stage2 ? clk_i : 1'b0;
    assign cs_no = ~spi_active_stage2;
    assign mosi_o = tx_shift_reg_stage2[DATA_WIDTH-1];
    
    // Pipeline stage 1 - 输入寄存阶段
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            enable_stage1 <= 1'b0;
            tx_data_stage1 <= {DATA_WIDTH{1'b0}};
            miso_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable_i;
            tx_data_stage1 <= tx_data_i;
            miso_stage1 <= miso_i;
        end
    end
    
    // Pipeline stage 2 - 事务启动控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            spi_active_stage2 <= 1'b0;
            sclk_enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 事务控制逻辑
            if (enable_stage1 && !spi_active_stage2 && !valid_stage2) begin
                // 开始新事务
                spi_active_stage2 <= 1'b1;
                sclk_enable_stage2 <= 1'b1;
                valid_stage2 <= 1'b1;
            end else if (valid_stage3 && bit_counter_stage3 >= DATA_WIDTH) begin
                // 当阶段3发出完成信号时结束事务
                spi_active_stage2 <= 1'b0;
                sclk_enable_stage2 <= 1'b0;
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2 - 数据寄存控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
            bit_counter_stage2 <= 0;
        end else begin
            // 数据加载和计数器控制
            if (enable_stage1 && !spi_active_stage2 && !valid_stage2) begin
                // 装载新数据
                tx_shift_reg_stage2 <= tx_data_stage1;
                bit_counter_stage2 <= 0;
            end else if (valid_stage3 && bit_counter_stage3 < DATA_WIDTH) begin
                // 从阶段3将数据传回阶段2以连续移位
                tx_shift_reg_stage2 <= tx_shift_reg_stage3;
                bit_counter_stage2 <= bit_counter_stage3;
            end
        end
    end
    
    // Pipeline stage 3 - 控制信号传播
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            spi_active_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // 传播控制信号
            spi_active_stage3 <= spi_active_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 3 - 发送数据移位操作
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_shift_reg_stage3 <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage2 && spi_active_stage2) begin
                if (bit_counter_stage2 < DATA_WIDTH) begin
                    // 发送数据移位操作
                    tx_shift_reg_stage3 <= {tx_shift_reg_stage2[DATA_WIDTH-2:0], 1'b0};
                end
            end else begin
                // 重置或不活动
                tx_shift_reg_stage3 <= tx_shift_reg_stage2;
            end
        end
    end
    
    // Pipeline stage 3 - 接收数据移位操作
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rx_shift_reg_stage3 <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage2 && spi_active_stage2) begin
                // 接收数据移位操作，在任何位计数条件下都执行
                rx_shift_reg_stage3 <= {rx_shift_reg_stage3[DATA_WIDTH-2:0], miso_stage1};
            end
        end
    end
    
    // Pipeline stage 3 - 位计数器控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bit_counter_stage3 <= 0;
        end else begin
            if (valid_stage2 && spi_active_stage2) begin
                if (bit_counter_stage2 < DATA_WIDTH) begin
                    // 位计数器增加
                    bit_counter_stage3 <= bit_counter_stage2 + 1'b1;
                end else begin
                    // 保持最终状态
                    bit_counter_stage3 <= bit_counter_stage2;
                end
            end else begin
                // 不活动时保持位计数器与stage2同步
                bit_counter_stage3 <= bit_counter_stage2;
            end
        end
    end
    
    // Pipeline stage 4 - 完成标志控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            completion_flag_stage4 <= 1'b0;
        end else begin
            if (valid_stage3 && bit_counter_stage3 == DATA_WIDTH && !completion_flag_stage4) begin
                // 事务完成 - 设置完成标志
                completion_flag_stage4 <= 1'b1;
            end else if (!valid_stage3) begin
                // 事务完成时重置完成标志
                completion_flag_stage4 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 4 - 输出数据控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rx_data_o <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage3 && bit_counter_stage3 == DATA_WIDTH && !completion_flag_stage4) begin
                // 事务完成 - 更新接收数据输出
                rx_data_o <= {rx_shift_reg_stage3[DATA_WIDTH-2:0], miso_stage1};
            end
        end
    end
    
    // Pipeline stage 4 - 完成信号控制
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_done_o <= 1'b0;
            rx_done_o <= 1'b0;
        end else begin
            // 默认状态为完成信号
            tx_done_o <= 1'b0;
            rx_done_o <= 1'b0;
            
            if (valid_stage3 && bit_counter_stage3 == DATA_WIDTH && !completion_flag_stage4) begin
                // 事务完成 - 激活完成信号
                tx_done_o <= 1'b1;
                rx_done_o <= 1'b1;
            end
        end
    end
endmodule