//SystemVerilog
module spi_clock_divider #(
    parameter SYS_CLK_FREQ    = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire [31:0] clk_divider, // 0 means use default
    input  wire [7:0]  tx_data,
    input  wire        start,
    output reg  [7:0]  rx_data,
    output reg         busy,
    output reg         done,
    output reg         spi_clk,
    output reg         spi_cs_n,
    output wire        spi_mosi,
    input  wire        spi_miso
);
    // Constant calculation at elaboration time
    localparam [31:0] DEFAULT_DIV = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);

    // Main state and data registers
    reg  [31:0] clk_counter_main, clk_counter_buf1, clk_counter_buf2;
    reg  [31:0] active_divider_reg;
    reg  [7:0]  tx_shift_main, tx_shift_buf1, tx_shift_buf2;
    reg  [7:0]  rx_shift_main;
    reg  [2:0]  bit_count_main;
    reg         busy_buf1, busy_buf2;
    reg         done_buf1, done_buf2;
    reg         spi_clk_buf1, spi_clk_buf2;

    // Divider selection logic (balanced)
    wire use_default_divider;
    assign use_default_divider = (clk_divider == 32'd0);

    wire [31:0] selected_divider;
    assign selected_divider = use_default_divider ? DEFAULT_DIV : clk_divider;

    // SPI MOSI output logic
    assign spi_mosi = tx_shift_buf2[7];

    // Buffer pipeline for high fanout signals
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            busy_buf1         <= 1'b0;
            busy_buf2         <= 1'b0;
            done_buf1         <= 1'b0;
            done_buf2         <= 1'b0;
            spi_clk_buf1      <= 1'b0;
            spi_clk_buf2      <= 1'b0;
            clk_counter_buf1  <= 32'd0;
            clk_counter_buf2  <= 32'd0;
            tx_shift_buf1     <= 8'd0;
            tx_shift_buf2     <= 8'd0;
        end else begin
            busy_buf1         <= busy;
            busy_buf2         <= busy_buf1;
            done_buf1         <= done;
            done_buf2         <= done_buf1;
            spi_clk_buf1      <= spi_clk;
            spi_clk_buf2      <= spi_clk_buf1;
            clk_counter_buf1  <= clk_counter_main;
            clk_counter_buf2  <= clk_counter_buf1;
            tx_shift_buf1     <= tx_shift_main;
            tx_shift_buf2     <= tx_shift_buf1;
        end
    end

    // Pre-balance key combinational conditions
    wire start_trig, spi_active, clk_edge, last_bit, clk_count_max;
    assign start_trig    = start & ~busy_buf2;
    assign spi_active    = busy_buf2;
    assign clk_count_max = (clk_counter_buf2 == (active_divider_reg - 1));
    assign last_bit      = (bit_count_main == 3'd0);
    assign clk_edge      = clk_count_max & spi_active;

    // Next state and data calculation (logic balanced)
    reg  [7:0]  rx_shift_next;
    reg  [7:0]  tx_shift_next;
    reg  [2:0]  bit_count_next;
    reg         busy_next;
    reg         done_next;
    reg         spi_clk_next;
    reg         spi_cs_n_next;
    reg  [7:0]  rx_data_next;
    reg  [31:0] clk_counter_next;
    reg  [31:0] active_divider_next;

    always @* begin
        // Default: hold state
        rx_shift_next       = rx_shift_main;
        tx_shift_next       = tx_shift_main;
        bit_count_next      = bit_count_main;
        busy_next           = busy;
        done_next           = 1'b0;
        spi_clk_next        = spi_clk;
        spi_cs_n_next       = spi_cs_n;
        rx_data_next        = rx_data;
        clk_counter_next    = clk_counter_main;
        active_divider_next = active_divider_reg;

        if (start_trig) begin
            active_divider_next = selected_divider;
            tx_shift_next       = tx_data;
            rx_shift_next       = 8'd0;
            bit_count_next      = 3'd7;
            busy_next           = 1'b1;
            done_next           = 1'b0;
            spi_cs_n_next       = 1'b0;
            clk_counter_next    = 32'd0;
            spi_clk_next        = 1'b0;
        end else if (clk_edge) begin
            clk_counter_next = 32'd0;
            spi_clk_next     = ~spi_clk_buf2;
            if (spi_clk_buf2) begin // Falling edge: Shift out and count
                if (last_bit) begin
                    busy_next     = 1'b0;
                    done_next     = 1'b1;
                    rx_data_next  = {rx_shift_main[6:0], spi_miso};
                    spi_cs_n_next = 1'b1;
                end else begin
                    tx_shift_next  = {tx_shift_buf2[6:0], 1'b0};
                    bit_count_next = bit_count_main - 3'd1;
                end
            end else begin // Rising edge: Sample in
                rx_shift_next = {rx_shift_main[6:0], spi_miso};
            end
        end else if (spi_active) begin
            clk_counter_next = clk_counter_buf2 + 32'd1;
        end
    end

    // Sequential state update
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_main   <= 32'd0;
            active_divider_reg <= DEFAULT_DIV;
            tx_shift_main      <= 8'd0;
            rx_shift_main      <= 8'd0;
            bit_count_main     <= 3'd0;
            busy               <= 1'b0;
            done               <= 1'b0;
            spi_clk            <= 1'b0;
            spi_cs_n           <= 1'b1;
            rx_data            <= 8'd0;
        end else begin
            clk_counter_main   <= clk_counter_next;
            active_divider_reg <= active_divider_next;
            tx_shift_main      <= tx_shift_next;
            rx_shift_main      <= rx_shift_next;
            bit_count_main     <= bit_count_next;
            busy               <= busy_next;
            done               <= done_next;
            spi_clk            <= spi_clk_next;
            spi_cs_n           <= spi_cs_n_next;
            rx_data            <= rx_data_next;
        end
    end

endmodule