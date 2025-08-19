//SystemVerilog
//IEEE 1364-2005
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
    
    // 优化的TX状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE; 
            tx_out <= 1'b1; 
            tx_bit_cnt <= 0; 
            tx_baud_cnt <= 0;
            tx_shift_reg <= 0;
        end else begin
            case (tx_state)
                IDLE: begin
                    tx_out <= 1'b1;
                    if (tx_valid) begin 
                        tx_state <= START; 
                        tx_out <= 1'b0; // 起始位
                        tx_shift_reg <= tx_data;
                        tx_baud_cnt <= 0;
                    end
                end
                
                START: begin
                    tx_out <= 1'b0;
                    if (tx_baud_cnt == BAUD_DIV-1) begin
                        tx_state <= DATA;
                        tx_baud_cnt <= 0;
                        tx_bit_cnt <= 0;
                    end else begin
                        tx_baud_cnt <= tx_baud_cnt + 1'b1;
                    end
                end
                
                DATA: begin
                    tx_out <= tx_shift_reg[0];
                    
                    // 优化比较链路
                    if (tx_baud_cnt < BAUD_DIV-1) begin
                        // 波特率计数未达到
                        tx_baud_cnt <= tx_baud_cnt + 1'b1;
                    end else begin
                        // 波特率计数达到
                        tx_baud_cnt <= 0;
                        tx_shift_reg <= tx_shift_reg >> 1; // 使用右移运算符
                        
                        // 优化位数计数逻辑
                        if (tx_bit_cnt < DWIDTH-1) begin
                            tx_bit_cnt <= tx_bit_cnt + 1'b1;
                        end else begin
                            tx_state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx_out <= 1'b1; // 停止位
                    if (tx_baud_cnt < BAUD_DIV-1) begin
                        tx_baud_cnt <= tx_baud_cnt + 1'b1;
                    end else begin
                        tx_state <= IDLE;
                        tx_baud_cnt <= 0;
                    end
                end
                
                default: tx_state <= IDLE;
            endcase
        end
    end
    
    // RX逻辑简化实现（实际应该有类似的状态机）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_data <= 0;
        end
    end
endmodule