//SystemVerilog
module usb_speed_negotiation(
    input wire clk,
    input wire rst_n,
    input wire bus_reset_detected,
    input wire chirp_k_detected,
    input wire chirp_j_detected,
    input wire high_speed_supported,
    input wire negotiation_enable,
    output reg dp_out,
    output reg dm_out,
    output reg dp_oe,
    output reg dm_oe,
    output reg [1:0] device_speed,
    output reg negotiation_complete,
    output reg [2:0] speed_state
);
    // Speed definitions
    localparam FULL_SPEED = 2'b00;
    localparam HIGH_SPEED = 2'b01;
    localparam LOW_SPEED = 2'b10;
    
    // State machine states
    localparam IDLE = 3'd0;
    localparam RESET = 3'd1;
    localparam CHIRP_K = 3'd2;
    localparam DETECT_HANDSHAKE = 3'd3;
    localparam SPEED_SELECTED = 3'd4;
    
    // 为高扇出信号添加缓冲寄存器
    reg [1:0] full_speed_buf1, full_speed_buf2;
    reg [1:0] d0_buf1, d0_buf2;
    reg [1:0] d1_buf1, d1_buf2;
    reg [15:0] chirp_counter;
    reg [15:0] chirp_counter_buf1, chirp_counter_buf2;
    reg [3:0] handshake_count;
    reg [3:0] handshake_count_buf1, handshake_count_buf2;
    
    // 分组负载的控制信号
    reg dp_oe_next, dm_oe_next;
    reg dp_out_next, dm_out_next;
    reg negotiation_complete_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 主状态寄存器复位
            speed_state <= IDLE;
            device_speed <= FULL_SPEED;
            negotiation_complete <= 1'b0;
            dp_out <= 1'b1;  // J state (full-speed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b1;
            dm_oe <= 1'b1;
            chirp_counter <= 16'd0;
            handshake_count <= 4'd0;
            
            // 缓冲寄存器复位
            full_speed_buf1 <= FULL_SPEED;
            full_speed_buf2 <= FULL_SPEED;
            d0_buf1 <= 2'b0;
            d0_buf2 <= 2'b0;
            d1_buf1 <= 2'b0;
            d1_buf2 <= 2'b0;
            chirp_counter_buf1 <= 16'd0;
            chirp_counter_buf2 <= 16'd0;
            handshake_count_buf1 <= 4'd0;
            handshake_count_buf2 <= 4'd0;
            
            dp_oe_next <= 1'b1;
            dm_oe_next <= 1'b1;
            dp_out_next <= 1'b1;
            dm_out_next <= 1'b0;
            negotiation_complete_next <= 1'b0;
        end else begin
            // 更新缓冲寄存器
            full_speed_buf1 <= FULL_SPEED;
            full_speed_buf2 <= full_speed_buf1;
            
            chirp_counter_buf1 <= chirp_counter;
            chirp_counter_buf2 <= chirp_counter_buf1;
            
            handshake_count_buf1 <= handshake_count;
            handshake_count_buf2 <= handshake_count_buf1;
            
            // 更新输出寄存器
            dp_oe <= dp_oe_next;
            dm_oe <= dm_oe_next;
            dp_out <= dp_out_next;
            dm_out <= dm_out_next;
            negotiation_complete <= negotiation_complete_next;
            
            // 扁平化的状态机逻辑
            if (speed_state == IDLE && bus_reset_detected) begin
                // IDLE状态检测到总线复位
                speed_state <= RESET;
                chirp_counter <= 16'd0;
                negotiation_complete_next <= 1'b0;
            end else if (speed_state == IDLE) begin
                // IDLE状态但没有复位
                negotiation_complete_next <= 1'b0;
            end else if (speed_state == RESET && !bus_reset_detected && high_speed_supported && negotiation_enable) begin
                // RESET状态结束，支持高速且使能协商
                speed_state <= CHIRP_K;
                dp_out_next <= 1'b0;  // K state
                dm_out_next <= 1'b1;
                dp_oe_next <= 1'b1;
                dm_oe_next <= 1'b1;
                chirp_counter <= 16'd0;
                handshake_count <= 4'd0;
            end else if (speed_state == RESET && !bus_reset_detected) begin
                // RESET状态结束，不进行高速协商
                speed_state <= SPEED_SELECTED;
                device_speed <= full_speed_buf1;  // 使用缓冲信号
                negotiation_complete_next <= 1'b1;
            end else if (speed_state == CHIRP_K) begin
                // CHIRP_K状态逻辑
                chirp_counter <= chirp_counter + 16'd1;
                if (chirp_counter >= 16'd7500) begin  // ~156.25µs K chirp
                    speed_state <= DETECT_HANDSHAKE;
                    dp_oe_next <= 1'b0;
                    dm_oe_next <= 1'b0;
                    chirp_counter <= 16'd0;
                end
            end else if (speed_state == DETECT_HANDSHAKE && chirp_j_detected && handshake_count < 4'd15) begin
                // 检测到J啁啾且计数未达到最大值
                handshake_count <= handshake_count + 4'd1;
                chirp_counter <= chirp_counter + 16'd1;
            end else if (speed_state == DETECT_HANDSHAKE && chirp_counter >= 16'd20000) begin
                // 握手检测超时
                speed_state <= SPEED_SELECTED;
                device_speed <= (handshake_count_buf1 >= 4'd3) ? HIGH_SPEED : full_speed_buf2;
                negotiation_complete_next <= 1'b1;
            end else if (speed_state == DETECT_HANDSHAKE) begin
                // 握手检测中但无其他事件
                chirp_counter <= chirp_counter + 16'd1;
            end else if (speed_state == SPEED_SELECTED && bus_reset_detected) begin
                // 速度已选择但检测到新的总线复位
                speed_state <= RESET;
                negotiation_complete_next <= 1'b0;
            end else if (speed_state == SPEED_SELECTED) begin
                // 速度已选择状态维护
                d0_buf1 <= {1'b0, device_speed == HIGH_SPEED};
                d0_buf2 <= d0_buf1;
                d1_buf1 <= {1'b0, device_speed == full_speed_buf1};
                d1_buf2 <= d1_buf1;
                
                // 使用缓冲后的译码信号设置线路状态
                if (d0_buf2[0]) begin
                    // High speed idle is SE0
                    dp_out_next <= 1'b0;
                    dm_out_next <= 1'b0;
                end else if (d1_buf2[0]) begin
                    // Full speed idle is J state
                    dp_out_next <= 1'b1;
                    dm_out_next <= 1'b0;
                end
                
                dp_oe_next <= 1'b1;
                dm_oe_next <= 1'b1;
            end
        end
    end
endmodule