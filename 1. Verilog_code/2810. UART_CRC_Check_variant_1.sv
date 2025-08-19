//SystemVerilog
module UART_CRC_Check #(
    parameter CRC_WIDTH = 16,
    parameter POLYNOMIAL = 16'h1021
)(
    input wire clk,
    input wire tx_start,
    input wire tx_active,
    input wire rx_start,
    input wire rx_active,
    input wire rxd,
    input wire [CRC_WIDTH-1:0] rx_crc,
    output reg crc_error,
    input wire [CRC_WIDTH-1:0] crc_seed
);

// CRC生成器
reg [CRC_WIDTH-1:0] crc_reg;
reg [1:0] tx_ctrl_state;

localparam TX_IDLE   = 2'b00;
localparam TX_START  = 2'b01;
localparam TX_ACTIVE = 2'b10;

always @(posedge clk) begin
    // 控制状态编码
    case ({tx_start, tx_active})
        2'b10: tx_ctrl_state <= TX_START;
        2'b01: tx_ctrl_state <= TX_ACTIVE;
        default: tx_ctrl_state <= TX_IDLE;
    endcase

    case (tx_ctrl_state)
        TX_START: begin
            crc_reg <= crc_seed;
        end
        TX_ACTIVE: begin
            crc_reg <= {crc_reg[CRC_WIDTH-2:0], 1'b0} ^ (crc_reg[CRC_WIDTH-1] ? POLYNOMIAL : {CRC_WIDTH{1'b0}});
        end
        default: begin
            crc_reg <= crc_reg;
        end
    endcase
end

// 接收校验单元
reg [CRC_WIDTH-1:0] crc_compare;
reg [1:0] rx_ctrl_state;

localparam RX_IDLE   = 2'b00;
localparam RX_START  = 2'b01;
localparam RX_ACTIVE = 2'b10;

always @(posedge clk) begin
    // 控制状态编码
    case ({rx_start, rx_active})
        2'b10: rx_ctrl_state <= RX_START;
        2'b01: rx_ctrl_state <= RX_ACTIVE;
        default: rx_ctrl_state <= RX_IDLE;
    endcase

    case (rx_ctrl_state)
        RX_START: begin
            crc_compare <= crc_seed;
        end
        RX_ACTIVE: begin
            crc_compare <= {crc_compare[CRC_WIDTH-2:0], rxd} ^ (crc_compare[CRC_WIDTH-1] ? POLYNOMIAL : {CRC_WIDTH{1'b0}});
        end
        default: begin
            crc_compare <= crc_compare;
        end
    endcase

    crc_error <= (crc_compare != rx_crc);
end

endmodule