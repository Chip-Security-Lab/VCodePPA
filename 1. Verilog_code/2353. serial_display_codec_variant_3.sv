//SystemVerilog
module serial_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input start_tx,
    output reg serial_data,
    output reg serial_clk,
    output reg tx_active,
    output reg tx_done
);
    // 寄存器声明
    reg [4:0] bit_counter;
    reg [15:0] shift_reg;
    reg [4:0] bit_counter_next;
    reg [15:0] shift_reg_next;
    reg serial_data_next;
    reg serial_clk_next;
    reg tx_active_next;
    reg tx_done_next;
    
    // 定义状态常量
    localparam IDLE = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // 状态寄存器
    reg [1:0] state, next_state;
    
    // 优化的RGB888到RGB565转换
    wire [15:0] rgb565_converted = {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]};
    
    // 组合逻辑部分 - 状态转换及控制信号
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        bit_counter_next = bit_counter;
        shift_reg_next = shift_reg;
        serial_data_next = serial_data;
        serial_clk_next = serial_clk;
        tx_active_next = tx_active;
        tx_done_next = tx_done;
        
        case (state)
            IDLE: begin
                if (start_tx) begin
                    // 开始传输
                    shift_reg_next = rgb565_converted;
                    bit_counter_next = 5'd0;
                    tx_active_next = 1'b1;
                    tx_done_next = 1'b0;
                    next_state = TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                // 生成串行时钟
                serial_clk_next = ~serial_clk;
                
                // 在时钟下降沿更新数据位
                if (serial_clk) begin
                    serial_data_next = shift_reg[15];
                    shift_reg_next = {shift_reg[14:0], 1'b0};
                    
                    // 使用比较器高效检查是否完成
                    if (bit_counter == 5'd15) begin
                        tx_active_next = 1'b0;
                        tx_done_next = 1'b1;
                        next_state = COMPLETE;
                    end else begin
                        bit_counter_next = bit_counter + 5'd1;
                    end
                end
            end
            
            COMPLETE: begin
                if (!start_tx) begin
                    // 复位完成信号
                    tx_done_next = 1'b0;
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 时序逻辑部分 - 更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
            serial_data <= 1'b0;
            serial_clk <= 1'b0;
            tx_active <= 1'b0;
            tx_done <= 1'b0;
            state <= IDLE;
        end else begin
            bit_counter <= bit_counter_next;
            shift_reg <= shift_reg_next;
            serial_data <= serial_data_next;
            serial_clk <= serial_clk_next;
            tx_active <= tx_active_next;
            tx_done <= tx_done_next;
            state <= next_state;
        end
    end
endmodule