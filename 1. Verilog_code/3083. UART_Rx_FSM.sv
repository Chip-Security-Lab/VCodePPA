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

            if (current_state != next_state) begin
                baud_counter <= 0;
                bit_counter <= 0;
            end else if (baud_counter < BAUD_DIV) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                bit_counter <= bit_counter + 1;
                
                // 在RECEIVING状态下，在适当的时钟周期采样rx_line
                if (current_state == RECEIVING) begin
                    shift_reg <= {rx_line, shift_reg[7:1]};
                end
            end
            
            // 当到达STOP状态且baud_counter达到一半时，更新rx_data并设置data_valid
            if (current_state == STOP && baud_counter == BAUD_DIV/2) begin
                rx_data <= shift_reg;
                data_valid <= 1;
            end
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: if (!rx_line) next_state = START_DET;
            START_DET: begin
                if (baud_counter == BAUD_DIV/2) begin
                    if (!rx_line) next_state = RECEIVING;
                    else next_state = IDLE;
                end
            end
            RECEIVING: begin
                if (bit_counter == 8) next_state = STOP;
            end
            STOP: begin
                if (baud_counter == BAUD_DIV) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule