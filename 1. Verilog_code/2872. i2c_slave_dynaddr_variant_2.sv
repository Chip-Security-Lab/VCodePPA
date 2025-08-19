//SystemVerilog
// SystemVerilog - IEEE 1364-2005
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

    // -------------------------------
    // 信号声明
    // -------------------------------
    
    // 流水线阶段1: 输入同步和滤波
    reg sda_sync_stage1, scl_sync_stage1;
    reg [FILTER_WIDTH-1:0] sda_filter_stage1, scl_filter_stage1;
    reg sda_filtered_stage1, scl_filtered_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 边沿检测
    reg sda_filtered_stage2, scl_filtered_stage2;
    reg sda_prev_stage2, scl_prev_stage2;
    reg start_detect_stage2, stop_detect_stage2;
    reg scl_rising_stage2, scl_falling_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 状态控制和位计数
    reg [7:0] shift_reg_stage3;
    reg [2:0] bit_cnt_stage3;
    reg addr_match_stage3;
    reg read_mode_stage3;
    reg valid_stage3;
    
    // 流水线阶段4: 地址匹配和数据输出
    reg [7:0] shift_reg_stage4;
    reg addr_match_stage4;
    reg read_mode_stage4;
    reg valid_stage4;
    
    // I2C状态定义 - 独热码编码
    localparam IDLE     = 7'b0000001;
    localparam START    = 7'b0000010;
    localparam ADDR     = 7'b0000100;
    localparam ACK_ADDR = 7'b0001000;
    localparam DATA     = 7'b0010000;
    localparam ACK_DATA = 7'b0100000;
    localparam STOP     = 7'b1000000;
    
    reg [6:0] state_stage3, state_stage4;
    wire [6:0] next_state;
    
    reg sda_out_en;
    reg sda_out_value;
    
    // -------------------------------
    // 组合逻辑部分
    // -------------------------------
    
    // 双向SDA控制 - 组合逻辑
    assign sda = sda_out_en ? sda_out_value : 1'bz;

    // 预计算滤波条件 - 组合逻辑
    wire sda_filter_all_zeros = (sda_filter_stage1 == {FILTER_WIDTH{1'b0}});
    wire sda_filter_all_ones = (sda_filter_stage1 == {FILTER_WIDTH{1'b1}});
    wire scl_filter_all_zeros = (scl_filter_stage1 == {FILTER_WIDTH{1'b0}});
    wire scl_filter_all_ones = (scl_filter_stage1 == {FILTER_WIDTH{1'b1}});
    
    // 状态转换和控制信号计算模块 - 纯组合逻辑
    i2c_slave_dynaddr_comb_logic state_comb_logic (
        .state_stage3(state_stage3),
        .bit_cnt_stage3(bit_cnt_stage3),
        .addr_match_stage3(addr_match_stage3),
        .start_detect_stage2(start_detect_stage2),
        .stop_detect_stage2(stop_detect_stage2),
        .scl_rising_stage2(scl_rising_stage2),
        .scl_falling_stage2(scl_falling_stage2),
        .next_state(next_state),
        .addr_phase_complete(addr_phase_complete),
        .data_phase_complete(data_phase_complete),
        .next_is_ack_addr(next_is_ack_addr),
        .next_is_ack_data(next_is_ack_data),
        .next_is_data(next_is_data)
    );

    // -------------------------------
    // 时序逻辑部分
    // -------------------------------
    
    // 流水线阶段1: 输入同步和滤波 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sync_stage1 <= 1'b1;
            scl_sync_stage1 <= 1'b1;
            sda_filter_stage1 <= {FILTER_WIDTH{1'b1}};
            scl_filter_stage1 <= {FILTER_WIDTH{1'b1}};
            sda_filtered_stage1 <= 1'b1;
            scl_filtered_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            // 同步输入
            sda_sync_stage1 <= sda;
            scl_sync_stage1 <= scl;
            
            // 移位寄存器滤波
            sda_filter_stage1 <= {sda_filter_stage1[FILTER_WIDTH-2:0], sda_sync_stage1};
            scl_filter_stage1 <= {scl_filter_stage1[FILTER_WIDTH-2:0], scl_sync_stage1};
            
            // 多数表决滤波器 - 使用预计算条件
            sda_filtered_stage1 <= sda_filter_all_zeros ? 1'b0 : 
                                  sda_filter_all_ones ? 1'b1 : sda_filtered_stage1;
            
            scl_filtered_stage1 <= scl_filter_all_zeros ? 1'b0 : 
                                  scl_filter_all_ones ? 1'b1 : scl_filtered_stage1;
            
            valid_stage1 <= 1'b1; // 这个阶段总是有效
        end
    end

    // 流水线阶段2: 边沿检测 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_filtered_stage2 <= 1'b1;
            scl_filtered_stage2 <= 1'b1;
            sda_prev_stage2 <= 1'b1;
            scl_prev_stage2 <= 1'b1;
            start_detect_stage2 <= 1'b0;
            stop_detect_stage2 <= 1'b0;
            scl_rising_stage2 <= 1'b0;
            scl_falling_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 寄存当前值
            sda_filtered_stage2 <= sda_filtered_stage1;
            scl_filtered_stage2 <= scl_filtered_stage1;
            sda_prev_stage2 <= sda_filtered_stage2;
            scl_prev_stage2 <= scl_filtered_stage2;
            
            // 检测START和STOP条件
            // START: SCL高时，SDA从高到低
            start_detect_stage2 <= scl_filtered_stage2 && sda_prev_stage2 && !sda_filtered_stage1;
            
            // STOP: SCL高时，SDA从低到高
            stop_detect_stage2 <= scl_filtered_stage2 && !sda_prev_stage2 && sda_filtered_stage1;
            
            // 检测SCL边沿
            scl_rising_stage2 <= !scl_prev_stage2 && scl_filtered_stage1;
            scl_falling_stage2 <= scl_prev_stage2 && !scl_filtered_stage1;
            
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // 流水线阶段3: 状态控制和位计数 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            bit_cnt_stage3 <= 3'd0;
            shift_reg_stage3 <= 8'd0;
            addr_match_stage3 <= 1'b0;
            read_mode_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            valid_stage3 <= 1'b1;
            state_stage3 <= next_state;
            
            // 根据预计算条件处理位计数器
            if (start_detect_stage2 || next_is_data || next_is_ack_data) begin
                bit_cnt_stage3 <= 3'd0;
            end else if (scl_rising_stage2 && (state_stage3[2] || state_stage3[4])) begin
                // 在ADDR或DATA状态且SCL上升沿时递增位计数
                bit_cnt_stage3 <= bit_cnt_stage3 + 1'b1;
            end
            
            // 处理移位寄存器
            if (scl_rising_stage2 && (state_stage3[2] || (state_stage3[4] && !read_mode_stage3))) begin
                // 在ADDR状态或写模式DATA状态时移位
                shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_filtered_stage2};
            end
            
            // 地址匹配和读/写模式识别
            if (addr_phase_complete) begin
                addr_match_stage3 <= (shift_reg_stage3[7:1] == slave_addr);
                read_mode_stage3 <= shift_reg_stage3[0];
            end
            
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // 流水线阶段4: 地址匹配和数据输出处理 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage4 <= 8'd0;
            addr_match_stage4 <= 1'b0;
            read_mode_stage4 <= 1'b0;
            state_stage4 <= IDLE;
            data_out <= 8'd0;
            data_valid <= 1'b0;
            sda_out_en <= 1'b0;
            sda_out_value <= 1'b1;
            valid_stage4 <= 1'b0;
        end else if (valid_stage3) begin
            shift_reg_stage4 <= shift_reg_stage3;
            addr_match_stage4 <= addr_match_stage3;
            read_mode_stage4 <= read_mode_stage3;
            state_stage4 <= state_stage3;
            valid_stage4 <= 1'b1;
            
            // 默认不激活数据有效信号
            data_valid <= 1'b0;
            
            // SDA输出控制
            case (1'b1) // 独热码状态机
                state_stage3[3]: begin // ACK_ADDR
                    sda_out_en <= addr_match_stage4;
                    sda_out_value <= 1'b0; // ACK
                end
                
                state_stage3[4]: begin // DATA
                    if (read_mode_stage4) begin
                        // 读模式，发送数据，但在ACK阶段除外
                        sda_out_en <= !(state_stage4[5] && scl_falling_stage2);
                        sda_out_value <= data_in[7-bit_cnt_stage3];
                    end else begin
                        sda_out_en <= 1'b0;
                        sda_out_value <= 1'b1;
                    end
                end
                
                state_stage3[5]: begin // ACK_DATA
                    if (!read_mode_stage4) begin
                        // 写模式ACK
                        sda_out_en <= 1'b1;
                        sda_out_value <= 1'b0;
                        
                        // 当从ACK_DATA转到DATA状态时，输出有效数据
                        if (state_stage4[5] && state_stage3[4] && bit_cnt_stage3 == 3'd0) begin
                            data_out <= shift_reg_stage4;
                            data_valid <= 1'b1;
                        end
                    end else begin
                        // 读模式，等待主机ACK
                        sda_out_en <= 1'b0;
                        sda_out_value <= 1'b1;
                    end
                end
                
                default: begin
                    sda_out_en <= 1'b0;
                    sda_out_value <= 1'b1;
                end
            endcase
        end else begin
            valid_stage4 <= 1'b0;
            data_valid <= 1'b0;
        end
    end

endmodule

// 状态转换组合逻辑模块 - 纯组合逻辑
module i2c_slave_dynaddr_comb_logic (
    input [6:0] state_stage3,
    input [2:0] bit_cnt_stage3,
    input addr_match_stage3,
    input start_detect_stage2,
    input stop_detect_stage2,
    input scl_rising_stage2,
    input scl_falling_stage2,
    
    output reg [6:0] next_state,
    output reg addr_phase_complete,
    output reg data_phase_complete,
    output reg next_is_ack_addr,
    output reg next_is_ack_data,
    output reg next_is_data
);
    
    // I2C状态定义 - 独热码编码
    localparam IDLE     = 7'b0000001;
    localparam START    = 7'b0000010;
    localparam ADDR     = 7'b0000100;
    localparam ACK_ADDR = 7'b0001000;
    localparam DATA     = 7'b0010000;
    localparam ACK_DATA = 7'b0100000;
    localparam STOP     = 7'b1000000;
    
    // 状态转换组合逻辑
    always @(*) begin
        // 默认保持当前状态
        next_state = state_stage3;
        addr_phase_complete = 1'b0;
        data_phase_complete = 1'b0;
        next_is_ack_addr = 1'b0;
        next_is_ack_data = 1'b0;
        next_is_data = 1'b0;
        
        // 检测特殊条件
        if (start_detect_stage2) begin
            next_state = START;
        end else if (stop_detect_stage2) begin
            next_state = IDLE;
        end else begin
            case (1'b1) // 独热码状态机case语句
                state_stage3[0]: begin // IDLE
                    // 保持IDLE状态
                end
                
                state_stage3[1]: begin // START
                    if (scl_rising_stage2) begin
                        next_state = ADDR;
                    end
                end
                
                state_stage3[2]: begin // ADDR
                    if (scl_rising_stage2 && bit_cnt_stage3 == 3'd7) begin
                        next_state = ACK_ADDR;
                        addr_phase_complete = 1'b1;
                        next_is_ack_addr = 1'b1;
                    end
                end
                
                state_stage3[3]: begin // ACK_ADDR
                    if (scl_falling_stage2) begin
                        next_state = addr_match_stage3 ? DATA : IDLE;
                        next_is_data = addr_match_stage3;
                    end
                end
                
                state_stage3[4]: begin // DATA
                    if (scl_rising_stage2 && bit_cnt_stage3 == 3'd7) begin
                        next_state = ACK_DATA;
                        data_phase_complete = 1'b1;
                        next_is_ack_data = 1'b1;
                    end
                end
                
                state_stage3[5]: begin // ACK_DATA
                    if (scl_falling_stage2) begin
                        next_state = DATA;
                        next_is_data = 1'b1;
                    end
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
    
endmodule