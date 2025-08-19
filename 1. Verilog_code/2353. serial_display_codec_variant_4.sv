//SystemVerilog (IEEE 1364-2005)
module serial_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input start_tx,
    output reg serial_data,
    output reg serial_clk,
    output reg tx_active,
    output reg tx_done
);
    // 流水线级别定义
    localparam STAGE_IDLE = 0;
    localparam STAGE_LOAD = 1;
    localparam STAGE_SHIFT = 2;
    
    // 流水线阶段寄存器
    reg [1:0] pipeline_stage, next_pipeline_stage;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg stage1_ready, stage2_ready;
    
    // 数据路径寄存器
    reg [23:0] rgb_stage1;
    reg [15:0] rgb565_stage2;  // RGB565格式
    reg [4:0] bit_counter_stage2;
    
    // 内部信号与缓冲
    reg serial_clk_int, serial_clk_int_stage2;
    reg start_tx_buf;
    
    // 阶段1: 输入缓冲和RGB转换准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_stage1 <= 24'd0;
            valid_stage1 <= 1'b0;
            start_tx_buf <= 1'b0;
        end else begin
            start_tx_buf <= start_tx;
            
            if (start_tx_buf && !tx_active && !tx_done && stage1_ready) begin
                rgb_stage1 <= rgb_in;
                valid_stage1 <= 1'b1;
            end else if (valid_stage1 && stage2_ready) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2: RGB888到RGB565转换和移位操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage2 <= 16'd0;
            bit_counter_stage2 <= 5'd0;
            valid_stage2 <= 1'b0;
            serial_clk_int <= 1'b0;
            serial_clk_int_stage2 <= 1'b0;
        end else begin
            // 时钟信号管理
            if (valid_stage2) begin
                serial_clk_int <= ~serial_clk_int;
                serial_clk_int_stage2 <= serial_clk_int;
            end
            
            // 数据加载和转换
            if (valid_stage1 && stage2_ready) begin
                // RGB888 to RGB565 conversion
                rgb565_stage2 <= {rgb_stage1[23:19], rgb_stage1[15:10], rgb_stage1[7:3]};
                bit_counter_stage2 <= 5'd0;
                valid_stage2 <= 1'b1;
            end else if (valid_stage2) begin
                // 数据移位操作
                if (serial_clk_int) begin
                    rgb565_stage2 <= {rgb565_stage2[14:0], 1'b0};
                    
                    if (bit_counter_stage2 == 5'd15) begin
                        valid_stage2 <= 1'b0;
                        bit_counter_stage2 <= 5'd0;
                    end else begin
                        bit_counter_stage2 <= bit_counter_stage2 + 5'd1;
                    end
                end
            end
        end
    end
    
    // 输出阶段: 输出控制和状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_data <= 1'b0;
            serial_clk <= 1'b0;
            tx_active <= 1'b0;
            tx_done <= 1'b0;
            stage1_ready <= 1'b1;
            stage2_ready <= 1'b1;
        end else begin
            // 数据输出和控制
            if (valid_stage2) begin
                tx_active <= 1'b1;
                serial_clk <= serial_clk_int_stage2;
                
                if (serial_clk_int) begin
                    serial_data <= rgb565_stage2[15];
                end
                
                if (bit_counter_stage2 == 5'd15 && serial_clk_int) begin
                    tx_done <= 1'b1;
                end
            end else begin
                if (!valid_stage1 && !valid_stage2) begin
                    tx_active <= 1'b0;
                end
                
                if (tx_done && !start_tx_buf) begin
                    tx_done <= 1'b0;
                end
            end
            
            // 流水线阶段就绪信号
            stage1_ready <= (!valid_stage1 || stage2_ready);
            stage2_ready <= !valid_stage2 || (bit_counter_stage2 == 5'd15 && serial_clk_int);
        end
    end
    
    // 流水线状态跟踪
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_stage <= STAGE_IDLE;
        end else begin
            pipeline_stage <= next_pipeline_stage;
        end
    end
    
    // 流水线状态控制
    always @(*) begin
        case (pipeline_stage)
            STAGE_IDLE: next_pipeline_stage = (start_tx_buf && !tx_active && !tx_done) ? STAGE_LOAD : STAGE_IDLE;
            STAGE_LOAD: next_pipeline_stage = (valid_stage1 && stage2_ready) ? STAGE_SHIFT : STAGE_LOAD;
            STAGE_SHIFT: next_pipeline_stage = (bit_counter_stage2 == 5'd15 && serial_clk_int) ? STAGE_IDLE : STAGE_SHIFT;
            default: next_pipeline_stage = STAGE_IDLE;
        endcase
    end
endmodule