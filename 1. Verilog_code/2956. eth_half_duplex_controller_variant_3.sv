//SystemVerilog
module eth_half_duplex_controller (
    input wire clk,
    input wire rst_n,
    // MAC layer interface
    input wire tx_request,
    output reg tx_grant,
    input wire tx_complete,
    input wire rx_active,
    // Status signals
    output reg [3:0] backoff_attempts,
    output reg [15:0] backoff_time,
    output reg carrier_sense,
    output reg collision_detected
);
    // 状态编码 - 使用单热编码提高性能和可读性
    localparam [5:0] IDLE     = 6'b000001,
                     SENSE    = 6'b000010,
                     TRANSMIT = 6'b000100,
                     COLLISION= 6'b001000,
                     BACKOFF  = 6'b010000,
                     IFG      = 6'b100000;
    
    localparam IFG_TIME = 16'd12; // 12 byte times
    localparam MAX_BACKOFF_ATTEMPTS = 4'd10;
    localparam MAX_BACKOFF_VALUE = 16'd1023; // 2^10 - 1
    
    reg [5:0] state, next_state;
    reg [15:0] timer, next_timer;
    reg next_tx_grant;
    reg [3:0] next_backoff_attempts;
    reg [15:0] next_backoff_time;
    reg next_carrier_sense;
    reg next_collision_detected;
    
    // 使用借位减法器替换普通减法器
    reg [15:0] timer_minus_1;
    reg [16:0] borrow; // 借位信号，比操作数多一位
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            timer <= 16'd0;
            tx_grant <= 1'b0;
            backoff_attempts <= 4'd0;
            backoff_time <= 16'd0;
            carrier_sense <= 1'b0;
            collision_detected <= 1'b0;
        end else begin
            state <= next_state;
            timer <= next_timer;
            tx_grant <= next_tx_grant;
            backoff_attempts <= next_backoff_attempts;
            backoff_time <= next_backoff_time;
            carrier_sense <= next_carrier_sense;
            collision_detected <= next_collision_detected;
        end
    end
    
    // 借位减法器实现
    always @(*) begin
        borrow[0] = 1'b0;
        for (integer i = 0; i < 16; i = i + 1) begin
            timer_minus_1[i] = timer[i] ^ 1'b1 ^ borrow[i];
            borrow[i+1] = (~timer[i]) & borrow[i] | (~timer[i]) & 1'b1 | borrow[i] & 1'b1;
        end
    end
    
    // 组合逻辑 - 下一状态和输出逻辑
    always @(*) begin
        // 默认值 - 维持当前状态
        next_state = state;
        next_timer = timer;
        next_tx_grant = tx_grant;
        next_backoff_attempts = backoff_attempts;
        next_backoff_time = backoff_time;
        next_carrier_sense = carrier_sense;
        next_collision_detected = collision_detected;
        
        case (state)
            IDLE: begin
                if (tx_request) begin
                    next_state = SENSE;
                    next_carrier_sense = 1'b0;
                    next_collision_detected = 1'b0;
                end
            end
            
            SENSE: begin
                // 媒体忙检测 (carrier sense)
                if (rx_active) begin
                    next_carrier_sense = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_carrier_sense = 1'b0;
                    next_tx_grant = 1'b1;
                    next_state = TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                // 优化后的冲突和传输完成检测
                if (rx_active) begin
                    next_collision_detected = 1'b1;
                    next_tx_grant = 1'b0;
                    next_backoff_attempts = (backoff_attempts < 4'd15) ? (backoff_attempts + 4'd1) : backoff_attempts;
                    next_state = COLLISION;
                end else if (tx_complete) begin
                    next_tx_grant = 1'b0;
                    next_backoff_attempts = 4'd0;
                    next_state = IFG;
                    next_timer = IFG_TIME;
                end
            end
            
            COLLISION: begin
                // 优化后的退避时间计算
                next_backoff_time = (backoff_attempts <= MAX_BACKOFF_ATTEMPTS) ? 
                                  ((16'd1 << backoff_attempts) - 16'd1) : 
                                  MAX_BACKOFF_VALUE;
                
                next_state = BACKOFF;
                next_timer = next_backoff_time;
                next_collision_detected = 1'b0;
            end
            
            BACKOFF: begin
                // 使用借位减法器实现减法
                if (timer == 16'd0) begin
                    next_state = IDLE;
                end else begin
                    next_timer = timer_minus_1;
                end
            end
            
            IFG: begin
                // 使用借位减法器实现减法
                if (timer == 16'd0) begin
                    next_state = IDLE;
                end else begin
                    next_timer = timer_minus_1;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule