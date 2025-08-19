//SystemVerilog
module UART_Rx_FSM #(
    parameter BAUD_DIV = 104  // 9600 baud @ 100MHz
)(
    input clk, rst_n,
    input rx_line,
    output reg [7:0] rx_data,
    output reg data_valid
);
    // 使用localparam代替typedef enum
    localparam IDLE = 2'b00, START_DET = 2'b01, RECEIVING = 2'b10, STOP = 2'b11;
    reg [1:0] current_state, next_state;
    reg [15:0] baud_counter;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg; // 添加移位寄存器存储接收的位
    
    // 优化比较操作的常量
    localparam HALF_BAUD = BAUD_DIV >> 1;
    
    // 状态转换和计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            baud_counter <= 0;
            bit_counter <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            data_valid <= 0;
        end else begin
            current_state <= next_state;
            data_valid <= 0; // 默认复位data_valid
            
            // 优化的状态变化检测
            if (current_state != next_state) begin
                baud_counter <= 0;
                bit_counter <= 0;
            end else begin
                // 优化波特率计数器逻辑
                if (baud_counter >= BAUD_DIV - 1) begin
                    baud_counter <= 0;
                    if (current_state == RECEIVING) begin
                        bit_counter <= bit_counter + 1;
                    end
                end else begin
                    baud_counter <= baud_counter + 1;
                end
                
                // 优化数据采样 - 只在RECEIVING状态且达到采样点时采样
                if (current_state == RECEIVING) begin
                    if (baud_counter == HALF_BAUD) begin
                        shift_reg <= {rx_line, shift_reg[7:1]};
                    end
                end
            end
            
            // 优化数据有效信号生成
            if (current_state == STOP) begin
                if (baud_counter == HALF_BAUD) begin
                    rx_data <= shift_reg;
                    data_valid <= 1;
                end
            end
        end
    end

    // 优化状态转换逻辑
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (rx_line) begin
                    next_state = IDLE;
                end else begin
                    next_state = START_DET;
                end
            end
            
            START_DET: begin
                if (baud_counter == HALF_BAUD) begin
                    if (rx_line) begin
                        next_state = IDLE;
                    end else begin
                        next_state = RECEIVING;
                    end
                end else begin
                    next_state = START_DET;
                end
            end
            
            RECEIVING: begin
                if (bit_counter == 8) begin
                    next_state = STOP;
                end else begin
                    next_state = RECEIVING;
                end
            end
            
            STOP: begin
                if (baud_counter == BAUD_DIV - 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = STOP;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule