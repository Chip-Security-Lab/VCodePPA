//SystemVerilog
module i2c_slave_dynaddr #(
    parameter FILTER_WIDTH = 3  // 输入滤波器参数
)(
    input clk,
    input rst_n,
    input scl,
    inout sda,
    output reg [7:0] data_out,
    output reg data_valid,
    input [7:0] data_in,
    input [6:0] slave_addr
);

// I2C 状态定义
localparam IDLE = 3'd0;
localparam START = 3'd1;
localparam ADDR = 3'd2;
localparam ACK_ADDR = 3'd3;
localparam DATA_RX = 3'd4;
localparam DATA_TX = 3'd5;
localparam ACK_DATA = 3'd6;
localparam STOP = 3'd7;

//==========================================================
// 输入同步与滤波阶段
//==========================================================
// Stage 1: 输入同步
reg sda_sync_s1, scl_sync_s1;

// Stage 2: 输入滤波
reg [1:0] sda_filter_s2, scl_filter_s2;
reg sda_filtered, scl_filtered;

// Stage 3: 边沿检测
reg scl_rising_s3, scl_falling_s3;
reg sda_rising_s3, sda_falling_s3;

// Stage 4: 条件检测
reg start_detect_s4, stop_detect_s4;

//==========================================================
// 状态控制阶段
//==========================================================
// 状态控制
reg [2:0] state_r, next_state;
reg [2:0] bit_cnt_r;
reg addr_match_r;

//==========================================================
// 数据处理阶段
//==========================================================
// 数据处理寄存器
reg [7:0] shift_reg_r;
reg [7:0] rx_data_buffer_r;
reg rx_data_valid_r;

//==========================================================
// 输出控制阶段
//==========================================================
// SDA输出控制
reg sda_out_r, sda_oe_r;
assign sda = sda_oe_r ? sda_out_r : 1'bz;

//==========================================================
// 输入同步与滤波路径实现
//==========================================================
// Stage 1: 输入同步 - 减少亚稳态风险
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sda_sync_s1 <= 1'b1;
        scl_sync_s1 <= 1'b1;
    end else begin
        sda_sync_s1 <= sda;
        scl_sync_s1 <= scl;
    end
end

// Stage 2: 输入滤波 - 消除输入噪声
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sda_filter_s2 <= 2'b11;
        scl_filter_s2 <= 2'b11;
        sda_filtered <= 1'b1;
        scl_filtered <= 1'b1;
    end else begin
        sda_filter_s2 <= {sda_filter_s2[0], sda_sync_s1};
        scl_filter_s2 <= {scl_filter_s2[0], scl_sync_s1};
        
        // 稳定滤波输出
        if (sda_filter_s2 == 2'b00) 
            sda_filtered <= 1'b0;
        else if (sda_filter_s2 == 2'b11)
            sda_filtered <= 1'b1;
            
        if (scl_filter_s2 == 2'b00)
            scl_filtered <= 1'b0;
        else if (scl_filter_s2 == 2'b11)
            scl_filtered <= 1'b1;
    end
end

// Stage 3: 边沿检测 - 识别信号跳变
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scl_rising_s3 <= 1'b0;
        scl_falling_s3 <= 1'b0;
        sda_rising_s3 <= 1'b0;
        sda_falling_s3 <= 1'b0;
    end else begin
        scl_rising_s3 <= (scl_filter_s2 == 2'b01);
        scl_falling_s3 <= (scl_filter_s2 == 2'b10);
        sda_rising_s3 <= (sda_filter_s2 == 2'b01);
        sda_falling_s3 <= (sda_filter_s2 == 2'b10);
    end
end

// Stage 4: 条件检测 - I2C协议条件识别
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_detect_s4 <= 1'b0;
        stop_detect_s4 <= 1'b0;
    end else begin
        // 起始条件: SCL高时SDA从高到低
        start_detect_s4 <= scl_filtered && sda_falling_s3;
        // 停止条件: SCL高时SDA从低到高
        stop_detect_s4 <= scl_filtered && sda_rising_s3;
    end
end

//==========================================================
// 状态控制实现
//==========================================================
// 状态寄存器更新
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_r <= IDLE;
    end else begin
        state_r <= next_state;
    end
end

// 状态转换逻辑 - 优化了状态转换条件
always @(*) begin
    next_state = state_r;
    
    case (state_r)
        IDLE: begin
            if (start_detect_s4)
                next_state = START;
        end
        
        START: begin
            if (scl_falling_s3)
                next_state = ADDR;
        end
        
        ADDR: begin
            if (bit_cnt_r == 3'd7 && scl_falling_s3)
                next_state = ACK_ADDR;
        end
        
        ACK_ADDR: begin
            if (scl_falling_s3) begin
                if (addr_match_r) begin
                    // 根据R/W位决定下一状态
                    next_state = shift_reg_r[0] ? DATA_TX : DATA_RX;
                end else
                    next_state = IDLE;
            end
        end
        
        DATA_RX: begin
            if (bit_cnt_r == 3'd7 && scl_falling_s3)
                next_state = ACK_DATA;
        end
        
        DATA_TX: begin
            if (bit_cnt_r == 3'd7 && scl_falling_s3)
                next_state = ACK_DATA;
        end
        
        ACK_DATA: begin
            if (scl_falling_s3)
                next_state = stop_detect_s4 ? IDLE : (shift_reg_r[0] ? DATA_TX : DATA_RX);
        end
        
        default: next_state = IDLE;
    endcase
    
    // 优先级更高的条件
    if (stop_detect_s4)
        next_state = IDLE;
end

// 位计数器 - 分离增强清晰度
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt_r <= 3'd0;
    end else if (state_r == IDLE || state_r == ACK_ADDR || state_r == ACK_DATA) begin
        bit_cnt_r <= 3'd0;
    end else if (scl_rising_s3 && (state_r == ADDR || state_r == DATA_RX || state_r == DATA_TX)) begin
        bit_cnt_r <= bit_cnt_r + 3'd1;
    end
end

//==========================================================
// 数据处理路径实现
//==========================================================
// 移位寄存器 - 数据接收与发送
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_r <= 8'h00;
    end else if (state_r == START) begin
        shift_reg_r <= 8'h00;
    end else if (scl_rising_s3) begin
        if (state_r == ADDR || state_r == DATA_RX) begin
            // 接收模式 - 移位数据
            shift_reg_r <= {shift_reg_r[6:0], sda_filtered};
        end
    end else if (scl_falling_s3 && state_r == DATA_TX && bit_cnt_r == 3'd0) begin
        // 发送模式 - 加载新数据
        shift_reg_r <= data_in;
    end
end

// 地址匹配检测 - 增强可读性
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_match_r <= 1'b0;
    end else if (state_r == ADDR && bit_cnt_r == 3'd7 && scl_falling_s3) begin
        // 比较接收到的地址与设定的从机地址
        addr_match_r <= (shift_reg_r[7:1] == slave_addr);
    end else if (state_r == IDLE) begin
        addr_match_r <= 1'b0;
    end
end

// 接收数据缓冲 - 分段读取数据路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_buffer_r <= 8'h00;
        rx_data_valid_r <= 1'b0;
    end else begin
        rx_data_valid_r <= 1'b0;
        
        if (state_r == DATA_RX && bit_cnt_r == 3'd7 && scl_falling_s3) begin
            rx_data_buffer_r <= {shift_reg_r[6:0], sda_filtered};
            rx_data_valid_r <= 1'b1;
        end
    end
end

// 输出数据寄存器 - 分离输出路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 8'h00;
        data_valid <= 1'b0;
    end else begin
        data_valid <= rx_data_valid_r;
        
        if (rx_data_valid_r) begin
            data_out <= rx_data_buffer_r;
        end
    end
end

//==========================================================
// 输出控制路径实现
//==========================================================
// SDA输出控制 - 优化三态控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sda_out_r <= 1'b1;
        sda_oe_r <= 1'b0;
    end else begin
        case (state_r)
            ACK_ADDR: begin
                if (addr_match_r) begin
                    sda_out_r <= 1'b0;  // ACK
                    sda_oe_r <= 1'b1;
                end else begin
                    sda_oe_r <= 1'b0;   // 地址不匹配，不驱动SDA
                end
            end
            
            DATA_TX: begin
                // 发送当前位
                sda_out_r <= shift_reg_r[7-bit_cnt_r];
                sda_oe_r <= 1'b1;
            end
            
            ACK_DATA: begin
                if (next_state == DATA_RX) begin  // 之前是DATA_RX状态
                    sda_out_r <= 1'b0;  // 接收数据后发送ACK
                    sda_oe_r <= 1'b1;
                end else begin
                    sda_oe_r <= 1'b0;   // 发送数据后接收主机ACK，不驱动SDA
                end
            end
            
            default: begin
                sda_out_r <= 1'b1;
                sda_oe_r <= 1'b0;       // 默认不驱动SDA
            end
        endcase
        
        // 在任何状态下，如果检测到停止条件，释放SDA线
        if (stop_detect_s4) begin
            sda_oe_r <= 1'b0;
        end
    end
end

endmodule