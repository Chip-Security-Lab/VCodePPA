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
    reg [15:0] baud_counter, baud_counter_next;
    reg [3:0] bit_counter, bit_counter_next;
    reg [7:0] shift_reg, shift_reg_next;
    reg rx_line_r1, rx_line_r2;
    reg data_valid_next;
    reg [7:0] rx_data_next;
    
    wire baud_counter_max = (baud_counter == BAUD_DIV);
    wire baud_counter_half = (baud_counter == BAUD_DIV/2);
    wire bit_counter_done = (bit_counter == 8);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_line_r1 <= 1'b1;
            rx_line_r2 <= 1'b1;
        end else begin
            rx_line_r1 <= rx_line;
            rx_line_r2 <= rx_line_r1;
        end
    end
    
    always @(*) begin
        next_state = current_state;
        baud_counter_next = baud_counter;
        bit_counter_next = bit_counter;
        shift_reg_next = shift_reg;
        data_valid_next = 1'b0;
        rx_data_next = rx_data;
        
        if (current_state == IDLE) begin
            if (!rx_line_r2) next_state = START_DET;
            baud_counter_next = 0;
            bit_counter_next = 0;
        end
        else if (current_state == START_DET) begin
            if (baud_counter_half) begin
                if (!rx_line_r2) next_state = RECEIVING;
                else next_state = IDLE;
                baud_counter_next = 0;
            end else begin
                baud_counter_next = baud_counter + 1'b1;
            end
        end
        else if (current_state == RECEIVING) begin
            if (baud_counter_max) begin
                baud_counter_next = 0;
                bit_counter_next = bit_counter + 1'b1;
                shift_reg_next = {rx_line_r2, shift_reg[7:1]};
                
                if (bit_counter_done) next_state = STOP;
            end else begin
                baud_counter_next = baud_counter + 1'b1;
            end
        end
        else if (current_state == STOP) begin
            if (baud_counter_half) begin
                rx_data_next = shift_reg;
                data_valid_next = 1'b1;
            end
            
            if (baud_counter_max) begin
                next_state = IDLE;
                baud_counter_next = 0;
            end else begin
                baud_counter_next = baud_counter + 1'b1;
            end
        end
        else begin
            next_state = IDLE;
        end
    end
    
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
            baud_counter <= baud_counter_next;
            bit_counter <= bit_counter_next;
            shift_reg <= shift_reg_next;
            rx_data <= rx_data_next;
            data_valid <= data_valid_next;
        end
    end
    
endmodule