//SystemVerilog
module i2c_slave_dynaddr #(
    parameter FILTER_WIDTH = 3  // 输入滤波器参数
)(
    input wire clk,
    input wire rst_n,
    input wire scl,
    inout wire sda,
    output reg [7:0] data_out,
    output reg data_valid,
    input wire [7:0] data_in,
    input wire [6:0] slave_addr
);

// 时钟缓冲分配
reg clk_buf1, clk_buf2, clk_buf3;
always @(*) begin
    clk_buf1 = clk;
    clk_buf2 = clk;
    clk_buf3 = clk;
end

// 使用同步器+移位寄存器的架构
reg [1:0] sda_sync_pipe, scl_sync_pipe;
reg [FILTER_WIDTH-1:0] sda_filter_main;
reg [FILTER_WIDTH-1:0] sda_filter_branch1, sda_filter_branch2;
reg [FILTER_WIDTH-1:0] scl_filter_main;
reg [FILTER_WIDTH-1:0] scl_filter_branch1, scl_filter_branch2;
reg [7:0] shift_reg_main;
reg [7:0] shift_reg_branch1, shift_reg_branch2;
reg [2:0] bit_cnt_main;
reg [2:0] bit_cnt_branch1, bit_cnt_branch2;
reg addr_match;
reg sda_out;
reg sda_en;
wire sda_filtered, scl_filtered;
wire scl_falling, scl_rising, sda_falling, sda_rising;

// 状态机状态定义
localparam [2:0] 
    IDLE = 3'b000,
    START = 3'b001,
    ADDR = 3'b010,
    ACK1 = 3'b011,
    DATA = 3'b100,
    ACK2 = 3'b101;
    
reg [2:0] state, next_state;

// 中间变量定义 - 引入中间变量简化条件判断
reg is_read_operation;       // 表示是否为读操作
reg is_write_operation;      // 表示是否为写操作
reg scl_filtered_active;     // SCL处于高电平状态
reg is_bit_count_max;        // 位计数到达最大值
reg is_stop_condition;       // 停止条件检测
reg is_start_condition;      // 开始条件检测

// 双级寄存器同步逻辑
always @(posedge clk_buf1 or negedge rst_n) begin
    if (!rst_n) begin
        sda_sync_pipe <= 2'b11;
        scl_sync_pipe <= 2'b11;
    end else begin
        sda_sync_pipe <= {sda_sync_pipe[0], sda};
        scl_sync_pipe <= {scl_sync_pipe[0], scl};
    end
end

// 优化后的输入滤波逻辑 - 主路径
always @(posedge clk_buf1 or negedge rst_n) begin
    if (!rst_n) begin
        sda_filter_main <= {FILTER_WIDTH{1'b1}};
        scl_filter_main <= {FILTER_WIDTH{1'b1}};
    end else begin
        sda_filter_main <= {sda_filter_main[FILTER_WIDTH-2:0], sda_sync_pipe[1]};
        scl_filter_main <= {scl_filter_main[FILTER_WIDTH-2:0], scl_sync_pipe[1]};
    end
end

// 分支路径缓冲寄存器 - 扇出缓冲1
always @(posedge clk_buf2 or negedge rst_n) begin
    if (!rst_n) begin
        sda_filter_branch1 <= {FILTER_WIDTH{1'b1}};
        scl_filter_branch1 <= {FILTER_WIDTH{1'b1}};
        shift_reg_branch1 <= 8'h00;
        bit_cnt_branch1 <= 3'b000;
    end else begin
        sda_filter_branch1 <= sda_filter_main;
        scl_filter_branch1 <= scl_filter_main;
        shift_reg_branch1 <= shift_reg_main;
        bit_cnt_branch1 <= bit_cnt_main;
    end
end

// 分支路径缓冲寄存器 - 扇出缓冲2
always @(posedge clk_buf3 or negedge rst_n) begin
    if (!rst_n) begin
        sda_filter_branch2 <= {FILTER_WIDTH{1'b1}};
        scl_filter_branch2 <= {FILTER_WIDTH{1'b1}};
        shift_reg_branch2 <= 8'h00;
        bit_cnt_branch2 <= 3'b000;
    end else begin
        sda_filter_branch2 <= sda_filter_main;
        scl_filter_branch2 <= scl_filter_main;
        shift_reg_branch2 <= shift_reg_main;
        bit_cnt_branch2 <= bit_cnt_main;
    end
end

// 优化的信号滤波检测逻辑 - 负载均衡
assign sda_filtered = &sda_filter_branch1;
assign scl_filtered = &scl_filter_branch1;
assign scl_rising = (scl_filter_branch1 == {{FILTER_WIDTH-1{1'b1}}, 1'b0});
assign scl_falling = (scl_filter_branch2 == {{FILTER_WIDTH-1{1'b0}}, 1'b1});
assign sda_rising = (sda_filter_branch1 == {{FILTER_WIDTH-1{1'b1}}, 1'b0});
assign sda_falling = (sda_filter_branch2 == {{FILTER_WIDTH-1{1'b0}}, 1'b1});

// 三态缓冲器逻辑
assign sda = sda_en ? sda_out : 1'bz;

// 状态寄存器更新
always @(posedge clk_buf1 or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 中间变量计算 - 简化条件逻辑
always @(*) begin
    // 操作类型判断
    is_read_operation = shift_reg_branch1[0];
    is_write_operation = !shift_reg_branch1[0];
    
    // 状态相关条件
    is_bit_count_max = (bit_cnt_branch1 == 3'b111);
    scl_filtered_active = scl_filtered;
    
    // I2C协议条件
    is_stop_condition = scl_filtered && sda_rising;
    is_start_condition = scl_filtered && sda_falling;
end

// 优化的状态转换和数据处理逻辑
always @(posedge clk_buf1 or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt_main <= 3'b000;
        shift_reg_main <= 8'h00;
        addr_match <= 1'b0;
        data_out <= 8'h00;
        data_valid <= 1'b0;
        sda_out <= 1'b1;
        sda_en <= 1'b0;
        next_state <= IDLE;
    end else begin
        // 默认值设置
        data_valid <= 1'b0;
        
        // 状态机逻辑分级处理
        case (state)
            IDLE: begin
                // IDLE状态处理
                sda_en <= 1'b0;
                
                // 检测开始条件
                if (is_start_condition) begin
                    next_state <= START;
                    bit_cnt_main <= 3'b000;
                end else begin
                    next_state <= IDLE;
                end
            end
            
            START: begin
                // START状态处理
                if (scl_falling) begin
                    next_state <= ADDR;
                    shift_reg_main <= 8'h00;
                end else begin
                    next_state <= START;
                end
            end
            
            ADDR: begin
                // ADDR状态处理
                if (scl_rising) begin
                    // 移位寄存器更新
                    shift_reg_main <= {shift_reg_branch1[6:0], sda_filtered};
                    bit_cnt_main <= bit_cnt_branch1 + 1'b1;
                    
                    // 位计数是否达到最大
                    if (is_bit_count_max) begin
                        next_state <= ACK1;
                        // 地址比较逻辑
                        addr_match <= (shift_reg_branch1[7:1] == slave_addr);
                    end else begin
                        next_state <= ADDR;
                    end
                end else begin
                    next_state <= ADDR;
                end
            end
            
            ACK1: begin
                // ACK1状态处理
                if (addr_match) begin
                    // 地址匹配情况
                    sda_en <= 1'b1;
                    sda_out <= 1'b0;
                    
                    if (scl_falling) begin
                        next_state <= DATA;
                        bit_cnt_main <= 3'b000;
                    end else begin
                        next_state <= ACK1;
                    end
                end else begin
                    // 地址不匹配情况
                    if (scl_falling) begin
                        next_state <= IDLE;
                    end else begin
                        next_state <= ACK1;
                    end
                end
            end
            
            DATA: begin
                // DATA状态处理 - 读操作
                if (is_read_operation) begin
                    if (scl_falling && bit_cnt_branch1 != 3'b000) begin
                        // 读操作SDA输出控制
                        sda_en <= 1'b1;
                        sda_out <= data_in[3'b111 - bit_cnt_branch1];
                    end
                    
                    // 移位寄存器处理
                    if (scl_rising) begin
                        bit_cnt_main <= bit_cnt_branch1 + 1'b1;
                        
                        if (is_bit_count_max) begin
                            next_state <= ACK2;
                        end else begin
                            next_state <= DATA;
                        end
                    end else begin
                        next_state <= DATA;
                    end
                end else begin
                    // DATA状态处理 - 写操作
                    sda_en <= 1'b0;
                    
                    if (scl_rising) begin
                        // 写操作移位寄存器和位计数更新
                        shift_reg_main <= {shift_reg_branch1[6:0], sda_filtered};
                        bit_cnt_main <= bit_cnt_branch1 + 1'b1;
                        
                        if (is_bit_count_max) begin
                            next_state <= ACK2;
                            data_out <= {shift_reg_branch1[6:0], sda_filtered};
                            data_valid <= 1'b1;
                        end else begin
                            next_state <= DATA;
                        end
                    end else begin
                        next_state <= DATA;
                    end
                end
            end
            
            ACK2: begin
                // ACK2状态处理
                if (is_write_operation) begin
                    // 写操作ACK处理
                    sda_en <= 1'b1;
                    sda_out <= 1'b0;
                end
                
                if (scl_falling) begin
                    next_state <= DATA;
                    bit_cnt_main <= 3'b000;
                    sda_en <= 1'b0;
                end else if (is_stop_condition) begin
                    next_state <= IDLE;
                end else begin
                    next_state <= ACK2;
                end
            end
            
            default: next_state <= IDLE;
        endcase
        
        // 全局停止条件检测 - 独立判断以确保及时响应
        if (is_stop_condition && state != IDLE) begin
            next_state <= IDLE;
            sda_en <= 1'b0;
        end
    end
end

endmodule