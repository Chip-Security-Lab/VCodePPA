//SystemVerilog
module uart_receiver(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] data_out,
    output reg data_valid
);
    parameter [2:0] IDLE = 3'b000, START_BIT = 3'b001, 
                    DATA_BITS = 3'b010, STOP_BIT = 3'b011;
    reg [2:0] state, next_state;
    reg [3:0] bit_count;
    reg [3:0] tick_count;
    reg [7:0] rx_shift_reg;
    
    // 预计算常量
    wire tick_middle = (tick_count == 4'h7);
    wire tick_sample = (tick_count == 4'hF);
    wire bit_complete = (bit_count == 7);
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (rx == 0) 
                    next_state = START_BIT;
            end
            START_BIT: begin
                if (baud_tick && tick_middle) 
                    next_state = DATA_BITS;
            end
            DATA_BITS: begin
                if (baud_tick && tick_sample) begin
                    if (bit_complete) 
                        next_state = STOP_BIT;
                end
            end
            STOP_BIT: begin
                if (baud_tick && tick_sample) 
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 数据和控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            tick_count <= 0;
            data_valid <= 0;
            rx_shift_reg <= 0;
            data_out <= 0;
        end else begin
            state <= next_state;
            
            // 计数器逻辑
            if (baud_tick) begin
                if (tick_count == 4'hF) 
                    tick_count <= 0; 
                else 
                    tick_count <= tick_count + 1;
            end
            
            // 数据位计数
            if (state == DATA_BITS && baud_tick && tick_sample) begin
                if (bit_complete) 
                    bit_count <= 0; 
                else 
                    bit_count <= bit_count + 1;
            end
            
            // 数据移位和采样
            if (state == DATA_BITS && baud_tick && tick_sample) begin
                rx_shift_reg <= {rx, rx_shift_reg[7:1]};
            end
            
            // 数据输出和有效信号
            if (state == STOP_BIT && baud_tick && tick_sample) begin
                data_out <= rx_shift_reg;
                data_valid <= 1;
            end else if (state == IDLE) begin
                data_valid <= 0;
            end
        end
    end
endmodule