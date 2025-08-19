//SystemVerilog
module spi_clock_divider #(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire [31:0] clk_divider, // 0 means use default
    input wire [7:0] tx_data,
    input wire start,
    output reg [7:0] rx_data,
    output reg busy,
    output reg done,

    output reg spi_clk,
    output reg spi_cs_n,
    output wire spi_mosi,
    input wire spi_miso
);

    localparam DEFAULT_DIV = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);

    // === Pipeline Stage 1: Control input latching and divider selection ===
    reg [31:0] clk_divider_stage1;
    reg [31:0] selected_divider_stage1;
    reg [7:0]  tx_data_stage1;
    reg        start_stage1;
    reg        use_default_div_stage1;
    reg        valid_stage1;
    reg        flush_stage1;

    // === Pipeline Stage 2: Divider setup and SPI transfer start ===
    reg [31:0] active_divider_stage2;
    reg [7:0]  tx_shift_stage2;
    reg [2:0]  bit_count_stage2;
    reg        busy_stage2;
    reg        done_stage2;
    reg        spi_cs_n_stage2;
    reg        valid_stage2;
    reg        flush_stage2;
    reg        start_stage2;
    reg [31:0] clk_counter_stage2;
    reg        spi_clk_stage2;
    reg [7:0]  rx_shift_stage2;

    // === Pipeline Stage 3: SPI transfer and output generation ===
    reg [31:0] clk_counter_stage3;
    reg [31:0] active_divider_stage3;
    reg [7:0]  tx_shift_stage3;
    reg [7:0]  rx_shift_stage3;
    reg [2:0]  bit_count_stage3;
    reg        busy_stage3;
    reg        done_stage3;
    reg        spi_clk_stage3;
    reg        spi_cs_n_stage3;
    reg        valid_stage3;
    reg        flush_stage3;
    reg        is_last_bit_stage3;
    reg        clk_counter_max_stage3;
    reg        spi_miso_stage3;
    reg [7:0]  rx_data_stage3;

    // Output assignment
    assign spi_mosi = tx_shift_stage3[7];

    // === Stage 1: Latch input and select divider ===
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_divider_stage1       <= 32'd0;
            selected_divider_stage1  <= DEFAULT_DIV;
            tx_data_stage1           <= 8'd0;
            start_stage1             <= 1'b0;
            use_default_div_stage1   <= 1'b1;
            valid_stage1             <= 1'b0;
            flush_stage1             <= 1'b0;
        end else begin
            clk_divider_stage1      <= clk_divider;
            tx_data_stage1          <= tx_data;
            start_stage1            <= start;
            use_default_div_stage1  <= (clk_divider == 32'd0);
            valid_stage1            <= 1'b1;
            flush_stage1            <= 1'b0;
            if (!start) begin
                valid_stage1        <= 1'b0;
            end
            selected_divider_stage1 <= (clk_divider == 32'd0) ? DEFAULT_DIV : clk_divider;
        end
    end

    // === Stage 2: Prepare for SPI transfer ===
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            active_divider_stage2 <= DEFAULT_DIV;
            tx_shift_stage2       <= 8'd0;
            bit_count_stage2      <= 3'd0;
            busy_stage2           <= 1'b0;
            done_stage2           <= 1'b0;
            spi_cs_n_stage2       <= 1'b1;
            valid_stage2          <= 1'b0;
            flush_stage2          <= 1'b0;
            start_stage2          <= 1'b0;
            clk_counter_stage2    <= 32'd0;
            spi_clk_stage2        <= 1'b0;
            rx_shift_stage2       <= 8'd0;
        end else begin
            if (valid_stage1 && start_stage1 && !busy_stage2) begin
                active_divider_stage2 <= selected_divider_stage1;
                tx_shift_stage2       <= tx_data_stage1;
                bit_count_stage2      <= 3'd7;
                busy_stage2           <= 1'b1;
                done_stage2           <= 1'b0;
                spi_cs_n_stage2       <= 1'b0;
                clk_counter_stage2    <= 32'd0;
                spi_clk_stage2        <= 1'b0;
                rx_shift_stage2       <= 8'd0;
                valid_stage2          <= 1'b1;
                flush_stage2          <= 1'b0;
                start_stage2          <= 1'b1;
            end else if (busy_stage2) begin
                valid_stage2          <= 1'b1;
                flush_stage2          <= 1'b0;
                start_stage2          <= 1'b0;
            end else begin
                valid_stage2          <= 1'b0;
                flush_stage2          <= 1'b0;
                start_stage2          <= 1'b0;
            end
        end
    end

    // === Stage 3: SPI transfer, shift, and output logic ===
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_stage3      <= 32'd0;
            active_divider_stage3   <= DEFAULT_DIV;
            tx_shift_stage3         <= 8'd0;
            rx_shift_stage3         <= 8'd0;
            bit_count_stage3        <= 3'd0;
            busy_stage3             <= 1'b0;
            done_stage3             <= 1'b0;
            spi_clk_stage3          <= 1'b0;
            spi_cs_n_stage3         <= 1'b1;
            valid_stage3            <= 1'b0;
            flush_stage3            <= 1'b0;
            is_last_bit_stage3      <= 1'b0;
            clk_counter_max_stage3  <= 1'b0;
            spi_miso_stage3         <= 1'b0;
            rx_data_stage3          <= 8'd0;
        end else begin
            // Latch inputs from stage2 into stage3 registers
            if (valid_stage2 && (start_stage2 || busy_stage2)) begin
                clk_counter_stage3      <= clk_counter_stage2;
                active_divider_stage3   <= active_divider_stage2;
                tx_shift_stage3         <= tx_shift_stage2;
                rx_shift_stage3         <= rx_shift_stage2;
                bit_count_stage3        <= bit_count_stage2;
                busy_stage3             <= busy_stage2;
                done_stage3             <= done_stage2;
                spi_clk_stage3          <= spi_clk_stage2;
                spi_cs_n_stage3         <= spi_cs_n_stage2;
                valid_stage3            <= 1'b1;
                flush_stage3            <= flush_stage2;
                is_last_bit_stage3      <= (bit_count_stage2 == 3'd0);
                clk_counter_max_stage3  <= (clk_counter_stage2 == (active_divider_stage2 - 1));
                spi_miso_stage3         <= spi_miso;
                rx_data_stage3          <= rx_data_stage3; // Hold previous unless updated below
            end else begin
                valid_stage3            <= 1'b0;
                flush_stage3            <= 1'b0;
            end

            // SPI transfer logic within stage3
            if (busy_stage3 && valid_stage3) begin
                if (clk_counter_max_stage3) begin
                    clk_counter_stage3 <= 32'd0;
                    spi_clk_stage3     <= ~spi_clk_stage3;

                    if (spi_clk_stage3) begin // Falling edge
                        if (is_last_bit_stage3) begin
                            busy_stage3    <= 1'b0;
                            done_stage3    <= 1'b1;
                            rx_data_stage3 <= {rx_shift_stage3[6:0], spi_miso_stage3};
                            spi_cs_n_stage3<= 1'b1;
                        end else begin
                            tx_shift_stage3<= {tx_shift_stage3[6:0], 1'b0};
                            bit_count_stage3 <= bit_count_stage3 - 1'b1;
                        end
                    end else begin // Rising edge
                        rx_shift_stage3  <= {rx_shift_stage3[6:0], spi_miso_stage3};
                    end
                end else begin
                    clk_counter_stage3 <= clk_counter_stage3 + 1'b1;
                end
            end else begin
                done_stage3 <= 1'b0;
            end
        end
    end

    // === Output Stage: Register outputs and drive external pins ===
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data   <= 8'd0;
            busy      <= 1'b0;
            done      <= 1'b0;
            spi_clk   <= 1'b0;
            spi_cs_n  <= 1'b1;
        end else begin
            rx_data   <= rx_data_stage3;
            busy      <= busy_stage3;
            done      <= done_stage3;
            spi_clk   <= spi_clk_stage3;
            spi_cs_n  <= spi_cs_n_stage3;
        end
    end

endmodule