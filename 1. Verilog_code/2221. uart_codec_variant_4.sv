//SystemVerilog
module uart_codec #(parameter DWIDTH = 8, parameter BAUD_DIV = 16)
(
    input wire clk, rst_n, tx_valid, rx_in,
    input wire [DWIDTH-1:0] tx_data,
    output reg rx_valid, tx_out,
    output reg [DWIDTH-1:0] rx_data
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    // TX相关寄存器
    reg [1:0] tx_state;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt;
    reg [DWIDTH-1:0] tx_shift_reg;
    
    // RX相关寄存器
    reg [1:0] rx_state;
    reg [$clog2(DWIDTH)-1:0] rx_bit_cnt;
    reg [$clog2(BAUD_DIV)-1:0] rx_baud_cnt;
    reg [DWIDTH-1:0] rx_shift_reg;
    
    // TX状态机控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
        end else case (tx_state)
            IDLE: begin
                if (tx_valid) 
                    tx_state <= START;
            end
            START: begin
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_state <= DATA;
            end
            DATA: begin
                if (tx_baud_cnt == BAUD_DIV-1 && tx_bit_cnt == DWIDTH-1)
                    tx_state <= STOP;
            end
            STOP: begin
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_state <= IDLE;
            end
            default: tx_state <= IDLE;
        endcase
    end
    
    // TX波特率计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_baud_cnt <= 0;
        end else case (tx_state)
            IDLE: begin
                if (tx_valid)
                    tx_baud_cnt <= 0;
            end
            START, DATA, STOP: begin
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_baud_cnt <= 0;
                else
                    tx_baud_cnt <= tx_baud_cnt + 1;
            end
            default: tx_baud_cnt <= 0;
        endcase
    end
    
    // TX位计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_bit_cnt <= 0;
        end else case (tx_state)
            IDLE, START: begin
                tx_bit_cnt <= 0;
            end
            DATA: begin
                if (tx_baud_cnt == BAUD_DIV-1 && tx_bit_cnt < DWIDTH-1)
                    tx_bit_cnt <= tx_bit_cnt + 1;
            end
            default: tx_bit_cnt <= 0;
        endcase
    end
    
    // TX移位寄存器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 0;
        end else case (tx_state)
            IDLE: begin
                if (tx_valid)
                    tx_shift_reg <= tx_data;
            end
            DATA: begin
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_shift_reg <= tx_shift_reg >> 1;
            end
            default: tx_shift_reg <= tx_shift_reg;
        endcase
    end
    
    // TX输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out <= 1'b1;
        end else case (tx_state)
            IDLE: begin
                tx_out <= 1'b1;
                if (tx_valid)
                    tx_out <= 1'b0; // 起始位
            end
            START: begin
                tx_out <= 1'b0; // 保持起始位
            end
            DATA: begin
                if (tx_baud_cnt == BAUD_DIV-1)
                    tx_out <= tx_shift_reg[0];
            end
            STOP: begin
                tx_out <= 1'b1; // 停止位
            end
            default: tx_out <= 1'b1;
        endcase
    end
    
    // RX状态机控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_bit_cnt <= 0;
            rx_baud_cnt <= 0;
            rx_shift_reg <= 0;
            rx_valid <= 1'b0;
            rx_data <= 0;
        end else begin
            // RX逻辑简化实现（与原始代码保持一致）
            rx_valid <= 1'b0;
        end
    end
    
endmodule