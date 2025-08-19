module uart_codec #(parameter DWIDTH = 8, parameter BAUD_DIV = 16)
(
    input wire clk, rst_n, tx_valid, rx_in,
    input wire [DWIDTH-1:0] tx_data,
    output reg rx_valid, tx_out,
    output reg [DWIDTH-1:0] rx_data
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] tx_state, rx_state;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt, rx_bit_cnt;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt, rx_baud_cnt;
    reg [DWIDTH-1:0] tx_shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE; 
            tx_out <= 1'b1; 
            tx_bit_cnt <= 0; 
            tx_baud_cnt <= 0;
            tx_shift_reg <= 0;
        end else case (tx_state)
            IDLE: if (tx_valid) begin 
                tx_state <= START; 
                tx_out <= 1'b0; // 起始位
                tx_shift_reg <= tx_data;
                tx_baud_cnt <= 0;
            end
            START: if (tx_baud_cnt == BAUD_DIV-1) begin 
                tx_state <= DATA; 
                tx_baud_cnt <= 0;
                tx_bit_cnt <= 0;
            end else 
                tx_baud_cnt <= tx_baud_cnt + 1;
            DATA: begin
                if (tx_baud_cnt == BAUD_DIV-1) begin
                    tx_out <= tx_shift_reg[0];
                    tx_shift_reg <= tx_shift_reg >> 1;
                    tx_baud_cnt <= 0;
                    if (tx_bit_cnt == DWIDTH-1)
                        tx_state <= STOP;
                    else
                        tx_bit_cnt <= tx_bit_cnt + 1;
                end else
                    tx_baud_cnt <= tx_baud_cnt + 1;
            end
            STOP: begin
                tx_out <= 1'b1; // 停止位
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_state <= IDLE;
                else
                    tx_baud_cnt <= tx_baud_cnt + 1;
            end
            default: tx_state <= IDLE;
        endcase
    end
    
    // RX逻辑简化实现（实际应该有类似的状态机）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_data <= 0;
        end
    end
endmodule