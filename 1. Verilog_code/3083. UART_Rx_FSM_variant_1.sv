//SystemVerilog
module UART_Rx_FSM #(
    parameter BAUD_DIV = 104  // 9600 baud @ 100MHz
)(
    input clk, rst_n,
    input rx_line,
    output reg [7:0] rx_data,
    output reg data_valid
);

    localparam IDLE = 2'b00, START_DET = 2'b01, RECEIVING = 2'b10, STOP = 2'b11;
    reg [1:0] current_state, next_state;
    reg [15:0] baud_counter;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg;
    
    // 预计算常用值
    localparam [15:0] BAUD_HALF = BAUD_DIV >> 1;
    localparam [3:0] BIT_MAX = 4'd8;
    
    // 状态转换逻辑
    always @(*) begin
        next_state = IDLE; // 默认状态
        
        case (current_state)
            IDLE: begin
                if (!rx_line) 
                    next_state = START_DET;
                else
                    next_state = IDLE;
            end
            
            START_DET: begin
                if (baud_counter == BAUD_HALF) begin
                    if (!rx_line)
                        next_state = RECEIVING;
                    else
                        next_state = IDLE;
                end else
                    next_state = START_DET;
            end
            
            RECEIVING: begin
                if (bit_counter == BIT_MAX)
                    next_state = STOP;
                else
                    next_state = RECEIVING;
            end
            
            STOP: begin
                if (baud_counter == BAUD_DIV)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end
        endcase
    end

    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 0;
            bit_counter <= 0;
        end else begin
            if (current_state != next_state) begin
                // 状态变化时重置计数器
                baud_counter <= 0;
                bit_counter <= 0;
            end else begin
                // 波特率计数器更新
                if (baud_counter < BAUD_DIV)
                    baud_counter <= baud_counter + 1'b1;
                
                // 比特计数器在波特率周期结束时更新
                if (baud_counter == BAUD_DIV && current_state == RECEIVING)
                    bit_counter <= bit_counter + 1'b1;
            end
        end
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'h0;
            rx_data <= 8'h0;
            data_valid <= 1'b0;
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
            data_valid <= 1'b0; // 默认为0，仅在特定条件下触发
            
            // 接收比特
            if (current_state == RECEIVING && baud_counter == BAUD_DIV)
                shift_reg <= {rx_line, shift_reg[7:1]};
                
            // 完成接收并输出数据
            if (current_state == STOP && baud_counter == BAUD_HALF) begin
                rx_data <= shift_reg;
                data_valid <= 1'b1;
            end
        end
    end
    
endmodule