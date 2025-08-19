//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module usb_protocol_analyzer(
    input  wire       clk,
    input  wire       reset,
    input  wire       dp,
    input  wire       dm,
    input  wire       start_capture,
    output wire [7:0] capture_data,
    output wire       data_valid,
    output wire [2:0] packet_type,
    output wire [7:0] capture_count
);
    // 内部信号定义
    wire j_state, k_state, se0;
    wire [2:0] state;
    wire capture_increment;
    
    // 子模块实例化
    usb_line_state_detector line_state_detector_inst (
        .dp(dp),
        .dm(dm),
        .j_state(j_state),
        .k_state(k_state),
        .se0(se0)
    );
    
    usb_state_machine state_machine_inst (
        .clk(clk),
        .reset(reset),
        .j_state(j_state),
        .k_state(k_state),
        .se0(se0),
        .start_capture(start_capture),
        .state(state),
        .capture_data(capture_data),
        .data_valid(data_valid),
        .packet_type(packet_type),
        .capture_increment(capture_increment)
    );
    
    usb_counter counter_inst (
        .clk(clk),
        .reset(reset),
        .capture_increment(capture_increment),
        .capture_count(capture_count)
    );
    
endmodule

// 线路状态检测子模块
module usb_line_state_detector(
    input  wire dp,
    input  wire dm,
    output wire j_state,
    output wire k_state,
    output wire se0
);
    // 使用中间变量提高可读性
    wire dp_high, dm_high;
    
    // 简化信号逻辑
    assign dp_high = dp;
    assign dm_high = dm;
    
    // USB 线路状态定义
    assign j_state = dp_high & ~dm_high;   // J state: D+ high, D- low
    assign k_state = ~dp_high & dm_high;   // K state: D+ low, D- high
    assign se0 = ~dp_high & ~dm_high;      // SE0: both D+ and D- low
    
endmodule

// 状态机子模块
module usb_state_machine(
    input  wire       clk,
    input  wire       reset,
    input  wire       j_state,
    input  wire       k_state,
    input  wire       se0,
    input  wire       start_capture,
    output reg  [2:0] state,
    output reg  [7:0] capture_data,
    output reg        data_valid,
    output reg  [2:0] packet_type,
    output wire       capture_increment
);
    // 状态定义
    localparam IDLE = 3'd0, SYNC = 3'd1, PID = 3'd2, DATA = 3'd3, EOP = 3'd4;
    
    // 内部寄存器
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    // 中间状态变量
    reg bit_count_max;
    reg valid_sync_pattern;
    reg should_transition_to_sync;
    reg should_transition_to_pid;
    reg should_transition_to_data;
    reg should_transition_to_eop;
    reg should_transition_to_idle;
    reg should_increment_bit_count;
    reg should_update_shift_reg;
    reg should_set_data_valid;
    
    // 传递计数增量信号到计数器模块
    assign capture_increment = data_valid;
    
    // 状态转换前置条件计算
    always @(*) begin
        // 默认值
        bit_count_max = (bit_count == 3'd7);
        valid_sync_pattern = (shift_reg == 8'b01010100); // SYNC pattern (reversed)
        
        // 状态转换判断
        should_transition_to_sync = (state == IDLE) && start_capture && k_state;
        should_transition_to_pid = (state == SYNC) && bit_count_max;
        should_transition_to_data = (state == PID) && bit_count_max;
        should_transition_to_eop = (state == DATA) && se0;
        should_transition_to_idle = (state == EOP);
        
        // 操作判断
        should_increment_bit_count = (state == SYNC) || (state == PID) || 
                                    ((state == DATA) && !se0);
        should_update_shift_reg = should_increment_bit_count;
        should_set_data_valid = ((state == PID) && bit_count_max) || 
                               ((state == DATA) && !se0 && bit_count_max);
    end
    
    // 主状态机
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            data_valid <= 1'b0;
            packet_type <= 3'd0;
            capture_data <= 8'd0;
        end else begin
            // 默认值设置
            data_valid <= 1'b0;
            
            // 状态转换逻辑
            if (should_transition_to_sync) begin
                state <= SYNC;
            end else if (should_transition_to_pid) begin
                state <= PID;
                bit_count <= 3'd0;
                if (valid_sync_pattern) begin
                    packet_type <= 3'd1; // Valid SYNC found
                end
            end else if (should_transition_to_data) begin
                state <= DATA;
                bit_count <= 3'd0;
            end else if (should_transition_to_eop) begin
                state <= EOP;
            end else if (should_transition_to_idle) begin
                state <= IDLE;
            end
            
            // 位计数器更新
            if (should_increment_bit_count) begin
                bit_count <= bit_count + 3'd1;
            end
            
            // 移位寄存器更新
            if (should_update_shift_reg) begin
                if (state == SYNC) begin
                    shift_reg <= {k_state, shift_reg[7:1]};
                end else begin
                    shift_reg <= {j_state, shift_reg[7:1]};
                end
            end
            
            // 数据输出
            if (should_set_data_valid) begin
                capture_data <= shift_reg;
                data_valid <= 1'b1;
            end
        end
    end
endmodule

// 计数器子模块
module usb_counter(
    input  wire       clk,
    input  wire       reset,
    input  wire       capture_increment,
    output reg  [7:0] capture_count
);
    // 中间变量
    reg should_increment;
    
    always @(*) begin
        should_increment = capture_increment;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            capture_count <= 8'd0;
        end else begin
            if (should_increment) begin
                capture_count <= capture_count + 8'd1;
            end
        end
    end
endmodule