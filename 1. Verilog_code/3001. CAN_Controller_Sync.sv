module CAN_Controller_Sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    input tx_valid,
    output reg tx_ready,
    output reg rx_valid
);
    // 状态编码
    localparam IDLE = 3'd0;
    localparam ARBITRATION = 3'd1;
    localparam DATA = 3'd2;
    localparam CRC = 3'd3;
    localparam ACK = 3'd4;
    
    reg [2:0] current_state, next_state;
    
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [3:0] bit_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            tx_ready <= 1'b1;
            rx_valid <= 1'b0;
            rx_data <= {DATA_WIDTH{1'b0}};
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            bit_counter <= 4'd0;
        end else begin
            current_state <= next_state;
            case(current_state)
                IDLE: if (tx_valid) begin
                    tx_shift_reg <= tx_data;
                    bit_counter <= DATA_WIDTH;
                    tx_ready <= 1'b0;
                    rx_valid <= 1'b0;
                end
                DATA: if (bit_counter > 0) begin
                    tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                    bit_counter <= bit_counter - 1;
                end
                ACK: begin
                    // 在ACK状态设置接收有效
                    rx_valid <= 1'b1;
                    rx_data <= tx_data; // 简化示例，实际应该从总线获取
                    tx_ready <= 1'b1;
                end
                default: begin
                    // 默认情况避免锁存器
                end
            endcase
        end
    end
    
    always @(*) begin
        next_state = current_state; // 默认保持状态
        case(current_state)
            IDLE: next_state = tx_valid ? ARBITRATION : IDLE;
            ARBITRATION: next_state = (can_rx) ? IDLE : DATA;
            DATA: next_state = (bit_counter == 0) ? CRC : DATA;
            CRC: next_state = ACK;
            ACK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1;
        end else begin
            case(current_state)
                ARBITRATION: can_tx <= 1'b0;
                DATA: can_tx <= tx_shift_reg[DATA_WIDTH-1];
                default: can_tx <= 1'b1;
            endcase
        end
    end
endmodule