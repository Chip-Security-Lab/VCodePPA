//SystemVerilog
module spi_variable_width(
    input               clk,
    input               rst_n,
    input      [4:0]    data_width, // 1-32 bits
    input      [31:0]   tx_data,
    input               start_tx,
    output reg [31:0]   rx_data,
    output reg          tx_done,
    output              sclk,
    output              cs_n,
    output              mosi,
    input               miso
);

    reg  [31:0] tx_shift_reg;
    reg  [31:0] rx_shift_reg;
    reg  [4:0]  bit_counter;
    reg         spi_busy;
    reg         sclk_reg;

    // Precompute data alignment shift amount for better path balance
    wire [5:0]  align_shift_amt;
    assign      align_shift_amt = 6'd32 - {1'b0, data_width};

    // MOSI is always the MSB of the shift reg
    assign mosi = tx_shift_reg[31];
    assign sclk = spi_busy ? sclk_reg : 1'b0;
    assign cs_n = ~spi_busy;

    // Decompose start condition for better logic balance
    wire start_condition;
    assign start_condition = start_tx & ~spi_busy;

    // Decompose bit_counter single-bit check for timing
    wire last_bit;
    assign last_bit = (bit_counter == 5'd1);

    // Precompute right-align shift amount for RX
    wire [5:0] rx_right_shift_amt;
    assign rx_right_shift_amt = 6'd32 - {1'b0, data_width};

    // SPI Busy and Start Condition Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_busy <= 1'b0;
        end else begin
            if (start_condition) begin
                spi_busy <= 1'b1;
            end else if (spi_busy && sclk_reg && last_bit) begin
                spi_busy <= 1'b0;
            end
        end
    end

    // SCLK Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_reg <= 1'b0;
        end else begin
            if (start_condition) begin
                sclk_reg <= 1'b0;
            end else if (spi_busy) begin
                sclk_reg <= ~sclk_reg;
            end
        end
    end

    // TX Shift Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 32'd0;
        end else begin
            if (start_condition) begin
                tx_shift_reg <= tx_data << align_shift_amt;
            end else if (spi_busy && sclk_reg) begin // Falling edge
                tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};
            end
        end
    end

    // RX Shift Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= 32'd0;
        end else begin
            if (start_condition) begin
                rx_shift_reg <= 32'd0;
            end else if (spi_busy && ~sclk_reg) begin // Rising edge
                rx_shift_reg <= {rx_shift_reg[30:0], miso};
            end
        end
    end

    // Bit Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
        end else begin
            if (start_condition) begin
                bit_counter <= data_width;
            end else if (spi_busy && sclk_reg) begin // Falling edge
                bit_counter <= bit_counter - 1'b1;
            end
        end
    end

    // TX Done and RX Data Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_done <= 1'b0;
            rx_data <= 32'd0;
        end else begin
            tx_done <= 1'b0;
            if (spi_busy && sclk_reg && last_bit) begin
                tx_done <= 1'b1;
                rx_data <= ((rx_shift_reg << 1) | miso) >> rx_right_shift_amt;
            end
        end
    end

endmodule