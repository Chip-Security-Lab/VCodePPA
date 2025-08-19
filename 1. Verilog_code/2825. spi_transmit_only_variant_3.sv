//SystemVerilog
module spi_transmit_only(
    input wire clk,
    input wire reset,
    input wire [15:0] tx_data,
    input wire tx_start,
    output reg tx_busy,
    output reg tx_done,
    output wire spi_clk,
    output wire spi_cs_n,
    output wire spi_mosi
);

    // Gray code state encoding for 3 states (expandable for up to 5)
    localparam [1:0] STATE_IDLE      = 2'b00; // 0
    localparam [1:0] STATE_TRANSMIT  = 2'b01; // 1
    localparam [1:0] STATE_FINISH    = 2'b11; // 3

    reg [1:0] current_state, next_state;
    reg [3:0] bit_counter, next_bit_counter;
    reg [15:0] data_shift_reg, next_data_shift_reg;
    reg spi_clk_reg, next_spi_clk_reg;
    reg next_tx_busy, next_tx_done;

    // SPI output assignments
    assign spi_mosi = data_shift_reg[15];
    assign spi_clk = (current_state == STATE_TRANSMIT) ? spi_clk_reg : 1'b0;
    assign spi_cs_n = (current_state == STATE_IDLE) || (current_state == STATE_FINISH);

    // State register and sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= STATE_IDLE;
            bit_counter <= 4'd0;
            data_shift_reg <= 16'd0;
            spi_clk_reg <= 1'b0;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            current_state <= next_state;
            bit_counter <= next_bit_counter;
            data_shift_reg <= next_data_shift_reg;
            spi_clk_reg <= next_spi_clk_reg;
            tx_busy <= next_tx_busy;
            tx_done <= next_tx_done;
        end
    end

    // Next-state and output logic with Gray code state encoding
    always @* begin
        // Default assignments
        next_state = current_state;
        next_bit_counter = bit_counter;
        next_data_shift_reg = data_shift_reg;
        next_spi_clk_reg = spi_clk_reg;
        next_tx_busy = tx_busy;
        next_tx_done = tx_done;

        case (current_state)
            STATE_IDLE: begin
                next_tx_done = 1'b0;
                next_tx_busy = 1'b0;
                next_spi_clk_reg = 1'b0;
                if (tx_start) begin
                    next_data_shift_reg = tx_data;
                    next_bit_counter = 4'd15;
                    next_tx_busy = 1'b1;
                    next_state = STATE_TRANSMIT;
                end
            end

            STATE_TRANSMIT: begin
                next_spi_clk_reg = ~spi_clk_reg;
                // Only act on the SPI clock falling edge for data shift
                if (!spi_clk_reg) begin
                    if (bit_counter <= 4'd0) begin
                        next_state = STATE_FINISH;
                    end else begin
                        next_bit_counter = bit_counter - 1'b1;
                        next_data_shift_reg = {data_shift_reg[14:0], 1'b0};
                    end
                end
            end

            STATE_FINISH: begin
                next_tx_busy = 1'b0;
                next_tx_done = 1'b1;
                next_spi_clk_reg = 1'b0;
                next_state = STATE_IDLE;
            end

            default: begin
                next_state = STATE_IDLE;
                next_bit_counter = 4'd0;
                next_data_shift_reg = 16'd0;
                next_spi_clk_reg = 1'b0;
                next_tx_busy = 1'b0;
                next_tx_done = 1'b0;
            end
        endcase
    end

endmodule