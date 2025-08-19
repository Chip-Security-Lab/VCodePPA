//SystemVerilog
module spi_master_configurable_valid_ready (
    input  wire        clock,
    input  wire        reset,
    input  wire        cpol,
    input  wire        cpha,
    input  wire        tx_valid,         // valid signal for tx_data
    output wire        tx_ready,         // ready signal for tx_data
    input  wire [7:0]  tx_data,
    output wire [7:0]  rx_data,
    output wire        rx_valid,         // valid signal for rx_data
    input  wire        rx_ready,         // ready signal for rx_data
    output wire        spi_clk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        cs_n
);

    // Internal signals
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg [3:0] bit_count;
    reg       sclk_internal;
    reg       master_ready, rx_valid_int;
    reg       enable_transfer;
    reg       cs_n_int;

    // Retimed input register for tx_data
    reg [7:0] tx_data_reg;
    reg       tx_valid_reg;
    reg       tx_handshake_reg;

    // Output registers for retiming
    reg [7:0] rx_data_reg;
    reg       rx_valid_reg;
    reg       cs_n_reg;

    // Valid-Ready handshake for TX
    assign tx_ready = master_ready & ~enable_transfer;
    // Valid-Ready handshake for RX
    assign rx_valid = rx_valid_reg;
    assign rx_data = rx_data_reg;

    // SPI clock generation
    assign spi_clk = (cpol) ? ~sclk_internal : sclk_internal;
    assign spi_mosi = tx_shift_reg[7];
    assign cs_n = cs_n_reg;

    // Retimed input register for tx_data and tx_valid
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            tx_data_reg      <= 8'h00;
            tx_valid_reg     <= 1'b0;
            tx_handshake_reg <= 1'b0;
        end else begin
            // Latch tx_data and tx_valid when handshake occurs
            if (tx_valid && tx_ready) begin
                tx_data_reg      <= tx_data;
                tx_valid_reg     <= 1'b1;
                tx_handshake_reg <= 1'b1;
            end else if (tx_handshake_reg && enable_transfer) begin
                tx_valid_reg     <= 1'b0;
                tx_handshake_reg <= 1'b0;
            end
        end
    end

    // Main state machine with retimed input registers
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            tx_shift_reg    <= 8'h00;
            rx_shift_reg    <= 8'h00;
            rx_data_reg     <= 8'h00;
            rx_valid_int    <= 1'b0;
            rx_valid_reg    <= 1'b0;
            bit_count       <= 4'd0;
            sclk_internal   <= 1'b0;
            master_ready    <= 1'b1;
            enable_transfer <= 1'b0;
            cs_n_int        <= 1'b1;
            cs_n_reg        <= 1'b1;
        end else begin
            // Default: no new RX data (internal signal)
            rx_valid_int <= 1'b0;

            // Initiate transfer if handshake is complete (use retimed tx_valid_reg and tx_data_reg)
            if (tx_valid_reg && tx_ready && ~enable_transfer && ~tx_handshake_reg) begin
                tx_shift_reg     <= tx_data_reg;
                bit_count        <= 4'd8;
                master_ready     <= 1'b0;
                enable_transfer  <= 1'b1;
                cs_n_int         <= 1'b0;
                sclk_internal    <= cpol; // Set initial clock phase
            end else if (enable_transfer) begin
                // SPI clock toggling
                sclk_internal <= ~sclk_internal;

                // Sampling and shifting on edges according to CPHA
                if (((sclk_internal && !cpha) || (!sclk_internal && cpha))) begin
                    rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                end
                if (((~sclk_internal && !cpha) || (sclk_internal && cpha))) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    bit_count <= bit_count - 4'd1;
                    if (bit_count == 4'd1) begin
                        master_ready    <= 1'b1;
                        enable_transfer <= 1'b0;
                        rx_valid_int    <= 1'b1;
                        rx_data_reg     <= {rx_shift_reg[6:0], spi_miso};
                        cs_n_int        <= 1'b1;
                    end
                end
            end
        end
    end

    // Output register retiming for rx_valid
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            rx_valid_reg <= 1'b0;
        end else begin
            if (rx_valid_int) begin
                rx_valid_reg <= 1'b1;
            end else if (rx_valid_reg && rx_ready) begin
                rx_valid_reg <= 1'b0;
            end
        end
    end

    // Output register retiming for cs_n
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            cs_n_reg <= 1'b1;
        end else begin
            cs_n_reg <= cs_n_int;
        end
    end

endmodule