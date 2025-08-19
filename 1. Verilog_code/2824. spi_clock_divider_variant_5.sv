//SystemVerilog
module spi_clock_divider #(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire [31:0] clk_divider,
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

    localparam [31:0] DEFAULT_DIV = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);

    // Stage 1: Latch Inputs
    reg start_valid_stage1;
    reg [31:0] clk_divider_stage1;
    reg [7:0] tx_data_stage1;

    // Stage 2: Divider Calculation and Setup
    reg start_valid_stage2;
    reg [31:0] clk_divider_stage2;
    reg [7:0] tx_data_stage2;
    reg [31:0] active_divider_stage2;
    reg [7:0] tx_shift_stage2;
    reg [2:0] bit_count_stage2;
    reg busy_stage2;
    reg done_stage2;
    reg spi_cs_n_stage2;
    reg [31:0] clk_counter_stage2;
    reg [7:0] rx_shift_stage2;
    reg spi_clk_stage2;
    reg valid_stage2;

    // Stage 3: Divider Counter and SPI Bit Transfer Prep
    reg [31:0] active_divider_stage3;
    reg [7:0] tx_shift_stage3;
    reg [2:0] bit_count_stage3;
    reg busy_stage3;
    reg done_stage3;
    reg spi_cs_n_stage3;
    reg [31:0] clk_counter_stage3;
    reg [7:0] rx_shift_stage3;
    reg spi_clk_stage3;
    reg valid_stage3;

    // Stage 4: SPI Bit Transfer
    reg [31:0] clk_counter_stage4;
    reg [7:0] tx_shift_stage4;
    reg [7:0] rx_shift_stage4;
    reg [2:0] bit_count_stage4;
    reg busy_stage4;
    reg done_stage4;
    reg [7:0] rx_data_stage4;
    reg spi_clk_stage4;
    reg spi_cs_n_stage4;
    reg valid_stage4;

    // Stage 5: Output Latch
    reg [7:0] rx_data_stage5;
    reg busy_stage5;
    reg done_stage5;
    reg spi_clk_stage5;
    reg spi_cs_n_stage5;
    reg valid_stage5;

    // Pipeline valid signals
    reg valid_stage1;
    reg flush_stage1, flush_stage2, flush_stage3, flush_stage4, flush_stage5;

    // MOSI Output Buffering (for fanout reduction)
    reg mosi_stage1, mosi_stage2;
    wire mosi_data_stage4 = tx_shift_stage4[7];
    assign spi_mosi = mosi_stage2;

    // Pipeline Stage 1: Latch Inputs
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            start_valid_stage1 <= 1'b0;
            clk_divider_stage1 <= 32'd0;
            tx_data_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
            flush_stage1 <= 1'b0;
        end else begin
            // If flush, clear valid
            if (flush_stage1) begin
                start_valid_stage1 <= 1'b0;
                valid_stage1 <= 1'b0;
            end else begin
                start_valid_stage1 <= start;
                clk_divider_stage1 <= clk_divider;
                tx_data_stage1 <= tx_data;
                valid_stage1 <= start;
            end
            flush_stage1 <= 1'b0;
        end
    end

    // Pipeline Stage 2: Divider Calculation and Setup
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            start_valid_stage2 <= 1'b0;
            clk_divider_stage2 <= 32'd0;
            tx_data_stage2 <= 8'd0;
            active_divider_stage2 <= DEFAULT_DIV;
            tx_shift_stage2 <= 8'd0;
            bit_count_stage2 <= 3'd0;
            busy_stage2 <= 1'b0;
            done_stage2 <= 1'b0;
            spi_cs_n_stage2 <= 1'b1;
            clk_counter_stage2 <= 32'd0;
            rx_shift_stage2 <= 8'd0;
            spi_clk_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            flush_stage2 <= 1'b0;
        end else begin
            if (flush_stage2) begin
                valid_stage2 <= 1'b0;
                busy_stage2 <= 1'b0;
                done_stage2 <= 1'b0;
            end else if (valid_stage1) begin
                start_valid_stage2 <= start_valid_stage1;
                clk_divider_stage2 <= clk_divider_stage1;
                tx_data_stage2 <= tx_data_stage1;
                active_divider_stage2 <= (clk_divider_stage1 == 32'd0) ? DEFAULT_DIV : clk_divider_stage1;
                tx_shift_stage2 <= tx_data_stage1;
                bit_count_stage2 <= 3'd7;
                busy_stage2 <= 1'b1;
                done_stage2 <= 1'b0;
                spi_cs_n_stage2 <= 1'b0;
                clk_counter_stage2 <= 32'd0;
                rx_shift_stage2 <= 8'd0;
                spi_clk_stage2 <= 1'b0;
                valid_stage2 <= 1'b1;
            end else begin
                // If not valid, hold values and clear valid
                valid_stage2 <= 1'b0;
                busy_stage2 <= 1'b0;
                done_stage2 <= 1'b0;
            end
            flush_stage2 <= 1'b0;
        end
    end

    // Pipeline Stage 3: Divider Counter and SPI Bit Transfer Prep
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            active_divider_stage3 <= DEFAULT_DIV;
            tx_shift_stage3 <= 8'd0;
            bit_count_stage3 <= 3'd0;
            busy_stage3 <= 1'b0;
            done_stage3 <= 1'b0;
            spi_cs_n_stage3 <= 1'b1;
            clk_counter_stage3 <= 32'd0;
            rx_shift_stage3 <= 8'd0;
            spi_clk_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            flush_stage3 <= 1'b0;
        end else begin
            if (flush_stage3) begin
                valid_stage3 <= 1'b0;
                busy_stage3 <= 1'b0;
                done_stage3 <= 1'b0;
            end else if (valid_stage2) begin
                active_divider_stage3 <= active_divider_stage2;
                tx_shift_stage3 <= tx_shift_stage2;
                bit_count_stage3 <= bit_count_stage2;
                busy_stage3 <= busy_stage2;
                done_stage3 <= done_stage2;
                spi_cs_n_stage3 <= spi_cs_n_stage2;
                clk_counter_stage3 <= clk_counter_stage2;
                rx_shift_stage3 <= rx_shift_stage2;
                spi_clk_stage3 <= spi_clk_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
                busy_stage3 <= 1'b0;
                done_stage3 <= 1'b0;
            end
            flush_stage3 <= 1'b0;
        end
    end

    // Pipeline Stage 4: SPI Bit Transfer
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_stage4 <= 32'd0;
            tx_shift_stage4 <= 8'd0;
            rx_shift_stage4 <= 8'd0;
            bit_count_stage4 <= 3'd0;
            busy_stage4 <= 1'b0;
            done_stage4 <= 1'b0;
            rx_data_stage4 <= 8'd0;
            spi_clk_stage4 <= 1'b0;
            spi_cs_n_stage4 <= 1'b1;
            valid_stage4 <= 1'b0;
            flush_stage4 <= 1'b0;
        end else begin
            if (flush_stage4) begin
                valid_stage4 <= 1'b0;
                busy_stage4 <= 1'b0;
                done_stage4 <= 1'b0;
            end else if (valid_stage3 && busy_stage3) begin
                // SPI clock divider logic
                if (clk_counter_stage3 >= active_divider_stage3 - 1) begin
                    clk_counter_stage4 <= 32'd0;
                    spi_clk_stage4 <= ~spi_clk_stage3;
                    if (spi_clk_stage3) begin // Falling edge
                        if (bit_count_stage3 == 0) begin
                            busy_stage4 <= 1'b0;
                            done_stage4 <= 1'b1;
                            rx_data_stage4 <= {rx_shift_stage3[6:0], spi_miso};
                            spi_cs_n_stage4 <= 1'b1;
                            tx_shift_stage4 <= tx_shift_stage3;
                            rx_shift_stage4 <= rx_shift_stage3;
                            bit_count_stage4 <= bit_count_stage3;
                        end else begin
                            tx_shift_stage4 <= {tx_shift_stage3[6:0], 1'b0};
                            bit_count_stage4 <= bit_count_stage3 - 1'b1;
                            rx_shift_stage4 <= rx_shift_stage3;
                            busy_stage4 <= 1'b1;
                            done_stage4 <= 1'b0;
                            spi_cs_n_stage4 <= spi_cs_n_stage3;
                        end
                    end else begin // Rising edge
                        rx_shift_stage4 <= {rx_shift_stage3[6:0], spi_miso};
                        tx_shift_stage4 <= tx_shift_stage3;
                        bit_count_stage4 <= bit_count_stage3;
                        busy_stage4 <= busy_stage3;
                        done_stage4 <= 1'b0;
                        spi_cs_n_stage4 <= spi_cs_n_stage3;
                    end
                end else begin
                    clk_counter_stage4 <= clk_counter_stage3 + 1'b1;
                    tx_shift_stage4 <= tx_shift_stage3;
                    rx_shift_stage4 <= rx_shift_stage3;
                    bit_count_stage4 <= bit_count_stage3;
                    busy_stage4 <= busy_stage3;
                    done_stage4 <= 1'b0;
                    spi_clk_stage4 <= spi_clk_stage3;
                    spi_cs_n_stage4 <= spi_cs_n_stage3;
                end
                valid_stage4 <= 1'b1;
            end else begin
                valid_stage4 <= 1'b0;
                busy_stage4 <= 1'b0;
                done_stage4 <= 1'b0;
            end
            flush_stage4 <= 1'b0;
        end
    end

    // Pipeline Stage 5: Output Latch
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data_stage5 <= 8'd0;
            busy_stage5 <= 1'b0;
            done_stage5 <= 1'b0;
            spi_clk_stage5 <= 1'b0;
            spi_cs_n_stage5 <= 1'b1;
            valid_stage5 <= 1'b0;
            flush_stage5 <= 1'b0;
        end else begin
            if (flush_stage5) begin
                valid_stage5 <= 1'b0;
                busy_stage5 <= 1'b0;
                done_stage5 <= 1'b0;
            end else if (valid_stage4) begin
                rx_data_stage5 <= rx_data_stage4;
                busy_stage5 <= busy_stage4;
                done_stage5 <= done_stage4;
                spi_clk_stage5 <= spi_clk_stage4;
                spi_cs_n_stage5 <= spi_cs_n_stage4;
                valid_stage5 <= 1'b1;
            end else begin
                valid_stage5 <= 1'b0;
                busy_stage5 <= 1'b0;
                done_stage5 <= 1'b0;
            end
            flush_stage5 <= 1'b0;
        end
    end

    // Output assignments
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data <= 8'd0;
            busy <= 1'b0;
            done <= 1'b0;
            spi_clk <= 1'b0;
            spi_cs_n <= 1'b1;
        end else begin
            rx_data <= rx_data_stage5;
            busy <= busy_stage5;
            done <= done_stage5;
            spi_clk <= spi_clk_stage5;
            spi_cs_n <= spi_cs_n_stage5;
        end
    end

    // MOSI Output Buffering (2-stage)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            mosi_stage1 <= 1'b0;
            mosi_stage2 <= 1'b0;
        end else begin
            mosi_stage1 <= mosi_data_stage4;
            mosi_stage2 <= mosi_stage1;
        end
    end

    // Pipeline Flush Logic (for reset and potential flush control)
    // Currently, only reset is supported, but can be extended for explicit flush
    always @(*) begin
        // No explicit flush in this version, only reset
        flush_stage1 = 1'b0;
        flush_stage2 = 1'b0;
        flush_stage3 = 1'b0;
        flush_stage4 = 1'b0;
        flush_stage5 = 1'b0;
    end

endmodule