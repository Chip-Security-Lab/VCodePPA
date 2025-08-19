//SystemVerilog
module usb_protocol_analyzer(
    input wire clk,
    input wire reset,
    input wire dp,
    input wire dm,
    input wire start_capture,
    output reg [7:0] capture_data,
    output reg data_valid,
    output reg [2:0] packet_type,
    output reg [7:0] capture_count
);
    // 状态定义
    localparam IDLE = 3'd0, SYNC = 3'd1, PID = 3'd2, DATA = 3'd3, EOP = 3'd4;
    
    // 内部寄存器
    reg [2:0] state, next_state;
    reg [2:0] bit_count, next_bit_count;
    reg [7:0] shift_reg, next_shift_reg;
    
    // 寄存器数据路径的中间值 - 重定时后的前级寄存器
    reg pre_data_valid;
    reg [2:0] pre_packet_type;
    reg [7:0] pre_capture_count;
    reg [7:0] pre_capture_data;
    
    // 中间寄存器更新信号
    reg update_pre_data_valid;
    reg update_pre_packet_type;
    reg update_pre_capture_count;
    reg update_pre_capture_data;
    
    // USB线路状态组合逻辑 - 用位操作合并检测
    wire [1:0] usb_state = {dp, dm};
    wire j_state = (usb_state == 2'b10);
    wire k_state = (usb_state == 2'b01);
    wire se0 = (usb_state == 2'b00);
    
    // 用于比较的常量
    localparam SYNC_PATTERN = 8'b01010100;
    localparam BIT_MAX = 3'd7;
    
    // 状态转换逻辑
    always @(*) begin
        // 默认值 - 保持当前状态
        next_state = state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        
        // 默认不更新中间寄存器
        update_pre_data_valid = 1'b0;
        update_pre_packet_type = 1'b0;
        update_pre_capture_count = 1'b0;
        update_pre_capture_data = 1'b0;
        
        case (state)
            IDLE: begin
                if (start_capture && k_state) begin
                    next_state = SYNC;
                    update_pre_capture_count = 1'b1;
                    pre_capture_count = 8'd0;
                end
            end
            
            SYNC: begin
                if (bit_count < BIT_MAX) begin
                    next_bit_count = bit_count + 3'd1;
                    next_shift_reg = {k_state, shift_reg[7:1]};
                end else begin
                    next_state = PID;
                    next_bit_count = 3'd0;
                    
                    // 更新packet_type的中间寄存器
                    if (shift_reg == SYNC_PATTERN) begin
                        update_pre_packet_type = 1'b1;
                        pre_packet_type = 3'd1;
                    end
                end
            end
            
            PID: begin
                if (bit_count < BIT_MAX) begin
                    next_bit_count = bit_count + 3'd1;
                    next_shift_reg = {j_state, shift_reg[7:1]};
                end else begin
                    // 更新中间寄存器
                    update_pre_capture_data = 1'b1;
                    pre_capture_data = shift_reg;
                    update_pre_data_valid = 1'b1;
                    pre_data_valid = 1'b1;
                    update_pre_capture_count = 1'b1;
                    pre_capture_count = pre_capture_count + 8'd1;
                    
                    next_state = DATA;
                    next_bit_count = 3'd0;
                end
            end
            
            DATA: begin
                if (se0) begin
                    next_state = EOP;
                end else if (bit_count < BIT_MAX) begin
                    next_bit_count = bit_count + 3'd1;
                    next_shift_reg = {j_state, shift_reg[7:1]};
                end else begin
                    // 更新中间寄存器
                    update_pre_capture_data = 1'b1;
                    pre_capture_data = shift_reg;
                    update_pre_data_valid = 1'b1;
                    pre_data_valid = 1'b1;
                    update_pre_capture_count = 1'b1;
                    pre_capture_count = pre_capture_count + 8'd1;
                    
                    next_bit_count = 3'd0;
                end
            end
            
            EOP: begin
                next_state = IDLE;
                update_pre_data_valid = 1'b1;
                pre_data_valid = 1'b0;
            end
            
            default: begin
                next_state = IDLE;  // 安全状态恢复
            end
        endcase
    end
    
    // 重定时 - 中间寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pre_data_valid <= 1'b0;
            pre_packet_type <= 3'd0;
            pre_capture_count <= 8'd0;
            pre_capture_data <= 8'd0;
        end else begin
            if (update_pre_data_valid)
                pre_data_valid <= pre_data_valid;
            if (update_pre_packet_type)
                pre_packet_type <= pre_packet_type;
            if (update_pre_capture_count)
                pre_capture_count <= pre_capture_count;
            if (update_pre_capture_data)
                pre_capture_data <= pre_capture_data;
        end
    end
    
    // 核心状态机寄存器更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
        end
    end
    
    // 输出寄存器更新 - 最后一级寄存器，从前级寄存器获取值
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_valid <= 1'b0;
            packet_type <= 3'd0;
            capture_count <= 8'd0;
            capture_data <= 8'd0;
        end else begin
            data_valid <= pre_data_valid;
            packet_type <= pre_packet_type;
            capture_count <= pre_capture_count;
            capture_data <= pre_capture_data;
        end
    end
endmodule