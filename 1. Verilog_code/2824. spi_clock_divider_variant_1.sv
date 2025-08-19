//SystemVerilog
module spi_clock_divider #(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input sys_clk,
    input sys_rst_n,
    input [31:0] clk_divider, // 0 means use default
    input [7:0] tx_data,
    input start,
    output [7:0] rx_data,
    output busy,
    output done,

    output spi_clk,
    output spi_cs_n,
    output spi_mosi,
    input spi_miso
);

    // Default divider param
    localparam [31:0] DEFAULT_DIV_LOCAL = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);

    // Buffered versions of high fanout signals
    reg [31:0] clk_divider_buf1, clk_divider_buf2;
    reg [31:0] default_div_buf1, default_div_buf2;
    reg [31:0] clk_counter_reg, clk_counter_buf1, clk_counter_buf2, clk_counter_pipe;
    reg [31:0] clk_counter_next;
    reg [31:0] active_divider_reg, active_divider_buf1, active_divider_buf2, active_divider_pipe;
    reg [31:0] active_divider_next;
    reg [7:0] tx_shift_reg, tx_shift_next, tx_shift_pipe;
    reg [7:0] rx_shift_reg, rx_shift_next, rx_shift_pipe;
    reg [2:0] bit_count_reg, bit_count_next, bit_count_pipe;
    reg busy_reg, busy_next, busy_pipe;
    reg done_reg, done_next, done_pipe;
    reg spi_clk_reg, spi_clk_next, spi_clk_pipe;
    reg spi_cs_n_reg, spi_cs_n_next, spi_cs_n_pipe;
    reg [7:0] rx_data_reg, rx_data_next, rx_data_pipe;

    // Output assignments
    assign rx_data = rx_data_pipe;
    assign busy = busy_pipe;
    assign done = done_pipe;
    assign spi_clk = spi_clk_pipe;
    assign spi_cs_n = spi_cs_n_pipe;
    assign spi_mosi = tx_shift_pipe[7];

    // Combinational logic for next-state
    reg [31:0] clk_counter_comb;
    reg [31:0] active_divider_comb;
    reg [7:0] tx_shift_comb;
    reg [7:0] rx_shift_comb;
    reg [2:0] bit_count_comb;
    reg busy_comb;
    reg done_comb;
    reg spi_clk_comb;
    reg spi_cs_n_comb;
    reg [7:0] rx_data_comb;

    // Buffering clk_divider and DEFAULT_DIV_LOCAL for fanout reduction
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_divider_buf1 <= 32'd0;
            clk_divider_buf2 <= 32'd0;
            default_div_buf1 <= DEFAULT_DIV_LOCAL;
            default_div_buf2 <= DEFAULT_DIV_LOCAL;
        end else begin
            clk_divider_buf1 <= clk_divider;
            clk_divider_buf2 <= clk_divider_buf1;
            default_div_buf1 <= DEFAULT_DIV_LOCAL;
            default_div_buf2 <= default_div_buf1;
        end
    end

    // Buffering clk_counter_reg for fanout reduction
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_buf1 <= 32'd0;
            clk_counter_buf2 <= 32'd0;
        end else begin
            clk_counter_buf1 <= clk_counter_reg;
            clk_counter_buf2 <= clk_counter_buf1;
        end
    end

    // Buffering active_divider_reg for fanout reduction
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            active_divider_buf1 <= DEFAULT_DIV_LOCAL;
            active_divider_buf2 <= DEFAULT_DIV_LOCAL;
        end else begin
            active_divider_buf1 <= active_divider_reg;
            active_divider_buf2 <= active_divider_buf1;
        end
    end

    // Buffering bit_count_reg for fanout reduction
    reg [2:0] bit_count_buf1, bit_count_buf2;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            bit_count_buf1 <= 3'd0;
            bit_count_buf2 <= 3'd0;
        end else begin
            bit_count_buf1 <= bit_count_reg;
            bit_count_buf2 <= bit_count_buf1;
        end
    end

    // Buffering tx_shift_reg for fanout reduction
    reg [7:0] tx_shift_buf1, tx_shift_buf2;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tx_shift_buf1 <= 8'd0;
            tx_shift_buf2 <= 8'd0;
        end else begin
            tx_shift_buf1 <= tx_shift_reg;
            tx_shift_buf2 <= tx_shift_buf1;
        end
    end

    // Buffering active_divider_next for fanout reduction
    reg [31:0] active_divider_next_buf1, active_divider_next_buf2;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            active_divider_next_buf1 <= DEFAULT_DIV_LOCAL;
            active_divider_next_buf2 <= DEFAULT_DIV_LOCAL;
        end else begin
            active_divider_next_buf1 <= active_divider_next;
            active_divider_next_buf2 <= active_divider_next_buf1;
        end
    end

    // Buffering clk_counter_next for fanout reduction
    reg [31:0] clk_counter_next_buf1, clk_counter_next_buf2;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_next_buf1 <= 32'd0;
            clk_counter_next_buf2 <= 32'd0;
        end else begin
            clk_counter_next_buf1 <= clk_counter_next;
            clk_counter_next_buf2 <= clk_counter_next_buf1;
        end
    end

    // Buffering signals for active_divider_next and clk_counter_next used in critical path
    wire [31:0] active_divider_for_comb = active_divider_next_buf2;
    wire [31:0] clk_counter_for_comb = clk_counter_next_buf2;

    // Combinational next-state logic
    always @* begin
        clk_counter_comb = clk_counter_pipe;
        active_divider_comb = active_divider_pipe;
        tx_shift_comb = tx_shift_pipe;
        rx_shift_comb = rx_shift_pipe;
        bit_count_comb = bit_count_pipe;
        busy_comb = busy_pipe;
        done_comb = done_pipe;
        spi_clk_comb = spi_clk_pipe;
        spi_cs_n_comb = spi_cs_n_pipe;
        rx_data_comb = rx_data_pipe;

        if (!sys_rst_n) begin
            clk_counter_comb = 32'd0;
            active_divider_comb = default_div_buf2;
            tx_shift_comb = 8'd0;
            rx_shift_comb = 8'd0;
            bit_count_comb = 3'd0;
            busy_comb = 1'b0;
            done_comb = 1'b0;
            spi_clk_comb = 1'b0;
            spi_cs_n_comb = 1'b1;
            rx_data_comb = 8'd0;
        end else if (start && !busy_pipe) begin
            active_divider_comb = (clk_divider_buf2 == 0) ? default_div_buf2 : clk_divider_buf2;
            tx_shift_comb = tx_data;
            bit_count_comb = 3'd7;
            busy_comb = 1'b1;
            done_comb = 1'b0;
            spi_cs_n_comb = 1'b0;
            clk_counter_comb = 32'd0;
        end else if (busy_pipe) begin
            if (clk_counter_pipe >= active_divider_pipe-1) begin
                clk_counter_comb = 32'd0;
                spi_clk_comb = ~spi_clk_pipe;

                if (spi_clk_pipe) begin // Falling edge
                    if (bit_count_pipe == 0) begin
                        busy_comb = 1'b0;
                        done_comb = 1'b1;
                        rx_data_comb = {rx_shift_pipe[6:0], spi_miso};
                        spi_cs_n_comb = 1'b1;
                    end else begin
                        tx_shift_comb = {tx_shift_pipe[6:0], 1'b0};
                        bit_count_comb = bit_count_pipe - 1;
                    end
                end else begin // Rising edge
                    rx_shift_comb = {rx_shift_pipe[6:0], spi_miso};
                end
            end else begin
                clk_counter_comb = clk_counter_pipe + 1;
            end
        end else begin
            done_comb = 1'b0;
        end
    end

    // First stage registers (register cut after input and before heavy logic)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_reg <= 32'd0;
            active_divider_reg <= DEFAULT_DIV_LOCAL;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            bit_count_reg <= 3'd0;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
            spi_clk_reg <= 1'b0;
            spi_cs_n_reg <= 1'b1;
            rx_data_reg <= 8'd0;
        end else begin
            clk_counter_reg <= clk_counter_next_buf2;
            active_divider_reg <= active_divider_next_buf2;
            tx_shift_reg <= tx_shift_next;
            rx_shift_reg <= rx_shift_next;
            bit_count_reg <= bit_count_next;
            busy_reg <= busy_next;
            done_reg <= done_next;
            spi_clk_reg <= spi_clk_next;
            spi_cs_n_reg <= spi_cs_n_next;
            rx_data_reg <= rx_data_next;
        end
    end

    // Pipeline register after first combinational stage
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_pipe <= 32'd0;
            active_divider_pipe <= DEFAULT_DIV_LOCAL;
            tx_shift_pipe <= 8'd0;
            rx_shift_pipe <= 8'd0;
            bit_count_pipe <= 3'd0;
            busy_pipe <= 1'b0;
            done_pipe <= 1'b0;
            spi_clk_pipe <= 1'b0;
            spi_cs_n_pipe <= 1'b1;
            rx_data_pipe <= 8'd0;
        end else begin
            clk_counter_pipe <= clk_counter_comb;
            active_divider_pipe <= active_divider_comb;
            tx_shift_pipe <= tx_shift_comb;
            rx_shift_pipe <= rx_shift_comb;
            bit_count_pipe <= bit_count_comb;
            busy_pipe <= busy_comb;
            done_pipe <= done_comb;
            spi_clk_pipe <= spi_clk_comb;
            spi_cs_n_pipe <= spi_cs_n_comb;
            rx_data_pipe <= rx_data_comb;
        end
    end

    // Next-state logic for first stage (register cut location)
    always @* begin
        clk_counter_next = clk_counter_reg;
        active_divider_next = active_divider_reg;
        tx_shift_next = tx_shift_reg;
        rx_shift_next = rx_shift_reg;
        bit_count_next = bit_count_reg;
        busy_next = busy_reg;
        done_next = done_reg;
        spi_clk_next = spi_clk_reg;
        spi_cs_n_next = spi_cs_n_reg;
        rx_data_next = rx_data_reg;

        // Pass-through to pipeline first stage (register cut)
        if (!sys_rst_n) begin
            clk_counter_next = 32'd0;
            active_divider_next = default_div_buf2;
            tx_shift_next = 8'd0;
            rx_shift_next = 8'd0;
            bit_count_next = 3'd0;
            busy_next = 1'b0;
            done_next = 1'b0;
            spi_clk_next = 1'b0;
            spi_cs_n_next = 1'b1;
            rx_data_next = 8'd0;
        end else if (start && !busy_reg) begin
            active_divider_next = (clk_divider_buf2 == 0) ? default_div_buf2 : clk_divider_buf2;
            tx_shift_next = tx_data;
            bit_count_next = 3'd7;
            busy_next = 1'b1;
            done_next = 1'b0;
            spi_cs_n_next = 1'b0;
            clk_counter_next = 32'd0;
        end else if (busy_reg) begin
            if (clk_counter_reg >= active_divider_reg-1) begin
                clk_counter_next = 32'd0;
                spi_clk_next = ~spi_clk_reg;

                if (spi_clk_reg) begin // Falling edge
                    if (bit_count_reg == 0) begin
                        busy_next = 1'b0;
                        done_next = 1'b1;
                        rx_data_next = {rx_shift_reg[6:0], spi_miso};
                        spi_cs_n_next = 1'b1;
                    end else begin
                        tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                        bit_count_next = bit_count_reg - 1;
                    end
                end else begin // Rising edge
                    rx_shift_next = {rx_shift_reg[6:0], spi_miso};
                end
            end else begin
                clk_counter_next = clk_counter_reg + 1;
            end
        end else begin
            done_next = 1'b0;
        end
    end

endmodule