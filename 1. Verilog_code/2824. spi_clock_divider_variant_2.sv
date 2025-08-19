//SystemVerilog
module spi_clock_divider #(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input            sys_clk,
    input            sys_rst_n,
    input  [31:0]    clk_divider,    // 0 means use default
    input  [7:0]     tx_data,
    input            start,
    output [7:0]     rx_data,
    output           busy,
    output           done,
    output           spi_clk,
    output           spi_cs_n,
    output           spi_mosi,
    input            spi_miso
);

    // ------------------------------------------------------------------------
    // Parameter and Localparam Definitions
    // ------------------------------------------------------------------------
    localparam DEFAULT_DIV = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);

    // ------------------------------------------------------------------------
    // Pipeline Stage 0: Divider Selection and Start Detection
    // ------------------------------------------------------------------------
    reg [31:0] active_divider_stage0;
    reg        start_pulse_stage0;

    typedef enum reg [1:0] {STAGE0_IDLE, STAGE0_START} stage0_state_t;
    reg [1:0] stage0_state, stage0_state_next;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            active_divider_stage0 <= DEFAULT_DIV;
            start_pulse_stage0    <= 1'b0;
            stage0_state          <= STAGE0_IDLE;
        end else begin
            stage0_state          <= stage0_state_next;
            case (stage0_state)
                STAGE0_IDLE: begin
                    if (start && !busy) begin
                        active_divider_stage0 <= (clk_divider == 0) ? DEFAULT_DIV : clk_divider;
                        start_pulse_stage0    <= 1'b1;
                    end else begin
                        active_divider_stage0 <= active_divider_stage0;
                        start_pulse_stage0    <= 1'b0;
                    end
                end
                STAGE0_START: begin
                    active_divider_stage0 <= active_divider_stage0;
                    start_pulse_stage0    <= 1'b0;
                end
                default: begin
                    active_divider_stage0 <= active_divider_stage0;
                    start_pulse_stage0    <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        case (stage0_state)
            STAGE0_IDLE: begin
                if (start && !busy)
                    stage0_state_next = STAGE0_START;
                else
                    stage0_state_next = STAGE0_IDLE;
            end
            STAGE0_START: stage0_state_next = STAGE0_IDLE;
            default: stage0_state_next = STAGE0_IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // Pipeline Stage 1: Transfer Control and Bit Counter
    // ------------------------------------------------------------------------
    reg [7:0]  tx_shift_stage1;
    reg [2:0]  bit_count_stage1;
    reg        busy_stage1;
    reg        done_stage1;
    reg        spi_cs_n_stage1;
    reg [7:0]  rx_shift_stage1;

    typedef enum reg [1:0] {STAGE1_IDLE, STAGE1_TRANSFER} stage1_state_t;
    reg [1:0] stage1_state, stage1_state_next;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tx_shift_stage1   <= 8'd0;
            bit_count_stage1  <= 3'd0;
            busy_stage1       <= 1'b0;
            done_stage1       <= 1'b0;
            spi_cs_n_stage1   <= 1'b1;
            rx_shift_stage1   <= 8'd0;
            stage1_state      <= STAGE1_IDLE;
        end else begin
            stage1_state      <= stage1_state_next;
            case (stage1_state)
                STAGE1_IDLE: begin
                    if (start_pulse_stage0) begin
                        tx_shift_stage1   <= tx_data;
                        bit_count_stage1  <= 3'd7;
                        busy_stage1       <= 1'b1;
                        done_stage1       <= 1'b0;
                        spi_cs_n_stage1   <= 1'b0;
                        rx_shift_stage1   <= 8'd0;
                    end else begin
                        tx_shift_stage1   <= tx_shift_stage1;
                        bit_count_stage1  <= bit_count_stage1;
                        busy_stage1       <= busy_stage1;
                        done_stage1       <= 1'b0;
                        spi_cs_n_stage1   <= spi_cs_n_stage1;
                        rx_shift_stage1   <= rx_shift_stage1;
                    end
                end
                STAGE1_TRANSFER: begin
                    tx_shift_stage1   <= tx_shift_stage1;
                    bit_count_stage1  <= bit_count_stage1;
                    busy_stage1       <= busy_stage1;
                    done_stage1       <= done_stage1;
                    spi_cs_n_stage1   <= spi_cs_n_stage1;
                    rx_shift_stage1   <= rx_shift_stage1;
                end
                default: begin
                    tx_shift_stage1   <= tx_shift_stage1;
                    bit_count_stage1  <= bit_count_stage1;
                    busy_stage1       <= busy_stage1;
                    done_stage1       <= 1'b0;
                    spi_cs_n_stage1   <= spi_cs_n_stage1;
                    rx_shift_stage1   <= rx_shift_stage1;
                end
            endcase
        end
    end

    always @(*) begin
        case (stage1_state)
            STAGE1_IDLE: begin
                if (start_pulse_stage0)
                    stage1_state_next = STAGE1_TRANSFER;
                else
                    stage1_state_next = STAGE1_IDLE;
            end
            STAGE1_TRANSFER: begin
                if (!busy_stage1)
                    stage1_state_next = STAGE1_IDLE;
                else
                    stage1_state_next = STAGE1_TRANSFER;
            end
            default: stage1_state_next = STAGE1_IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // Pipeline Stage 2: Clock Divider and SPI Clock Generation
    // ------------------------------------------------------------------------
    reg [31:0] clk_counter_stage2;
    reg        spi_clk_stage2;
    reg [31:0] active_divider_stage2;
    reg [7:0]  tx_shift_stage2;
    reg [7:0]  rx_shift_stage2;
    reg [2:0]  bit_count_stage2;
    reg        busy_stage2;
    reg        done_stage2;
    reg        spi_cs_n_stage2;
    reg [7:0]  rx_data_stage2;

    typedef enum reg [1:0] {STAGE2_IDLE, STAGE2_TRANSFER} stage2_state_t;
    reg [1:0] stage2_state, stage2_state_next;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter_stage2     <= 32'd0;
            spi_clk_stage2         <= 1'b0;
            active_divider_stage2  <= DEFAULT_DIV;
            tx_shift_stage2        <= 8'd0;
            rx_shift_stage2        <= 8'd0;
            bit_count_stage2       <= 3'd0;
            busy_stage2            <= 1'b0;
            done_stage2            <= 1'b0;
            spi_cs_n_stage2        <= 1'b1;
            rx_data_stage2         <= 8'd0;
            stage2_state           <= STAGE2_IDLE;
        end else begin
            stage2_state           <= stage2_state_next;
            case (stage2_state)
                STAGE2_IDLE: begin
                    if (start_pulse_stage0) begin
                        clk_counter_stage2     <= 32'd0;
                        spi_clk_stage2         <= 1'b0;
                        active_divider_stage2  <= active_divider_stage0;
                        tx_shift_stage2        <= tx_data;
                        rx_shift_stage2        <= 8'd0;
                        bit_count_stage2       <= 3'd7;
                        busy_stage2            <= 1'b1;
                        done_stage2            <= 1'b0;
                        spi_cs_n_stage2        <= 1'b0;
                        rx_data_stage2         <= rx_data_stage2;
                    end else begin
                        clk_counter_stage2     <= clk_counter_stage2;
                        spi_clk_stage2         <= spi_clk_stage2;
                        active_divider_stage2  <= active_divider_stage2;
                        tx_shift_stage2        <= tx_shift_stage2;
                        rx_shift_stage2        <= rx_shift_stage2;
                        bit_count_stage2       <= bit_count_stage2;
                        busy_stage2            <= busy_stage2;
                        done_stage2            <= 1'b0;
                        spi_cs_n_stage2        <= spi_cs_n_stage2;
                        rx_data_stage2         <= rx_data_stage2;
                    end
                end
                STAGE2_TRANSFER: begin
                    if (clk_counter_stage2 >= active_divider_stage2-1) begin
                        clk_counter_stage2 <= 32'd0;
                        spi_clk_stage2     <= ~spi_clk_stage2;
                        case (spi_clk_stage2)
                            1'b1: begin
                                if (bit_count_stage2 == 0) begin
                                    busy_stage2     <= 1'b0;
                                    done_stage2     <= 1'b1;
                                    rx_data_stage2  <= {rx_shift_stage2[6:0], spi_miso};
                                    spi_cs_n_stage2 <= 1'b1;
                                    tx_shift_stage2 <= tx_shift_stage2;
                                    bit_count_stage2<= bit_count_stage2;
                                    rx_shift_stage2 <= rx_shift_stage2;
                                end else begin
                                    tx_shift_stage2 <= {tx_shift_stage2[6:0], 1'b0};
                                    bit_count_stage2<= bit_count_stage2 - 1;
                                    rx_shift_stage2 <= rx_shift_stage2;
                                    rx_data_stage2  <= rx_data_stage2;
                                    spi_cs_n_stage2 <= spi_cs_n_stage2;
                                end
                            end
                            1'b0: begin
                                rx_shift_stage2  <= {rx_shift_stage2[6:0], spi_miso};
                                tx_shift_stage2  <= tx_shift_stage2;
                                bit_count_stage2 <= bit_count_stage2;
                                rx_data_stage2   <= rx_data_stage2;
                                spi_cs_n_stage2  <= spi_cs_n_stage2;
                            end
                        endcase
                    end else begin
                        clk_counter_stage2 <= clk_counter_stage2 + 1;
                        tx_shift_stage2    <= tx_shift_stage2;
                        rx_shift_stage2    <= rx_shift_stage2;
                        bit_count_stage2   <= bit_count_stage2;
                        busy_stage2        <= busy_stage2;
                        done_stage2        <= done_stage2;
                        spi_clk_stage2     <= spi_clk_stage2;
                        spi_cs_n_stage2    <= spi_cs_n_stage2;
                        rx_data_stage2     <= rx_data_stage2;
                    end
                end
                default: begin
                    done_stage2 <= 1'b0;
                    tx_shift_stage2 <= tx_shift_stage2;
                    rx_shift_stage2 <= rx_shift_stage2;
                    bit_count_stage2 <= bit_count_stage2;
                    busy_stage2 <= busy_stage2;
                    spi_clk_stage2 <= spi_clk_stage2;
                    spi_cs_n_stage2 <= spi_cs_n_stage2;
                    rx_data_stage2 <= rx_data_stage2;
                    clk_counter_stage2 <= clk_counter_stage2;
                    active_divider_stage2 <= active_divider_stage2;
                end
            endcase
        end
    end

    always @(*) begin
        case (stage2_state)
            STAGE2_IDLE: begin
                if (start_pulse_stage0)
                    stage2_state_next = STAGE2_TRANSFER;
                else
                    stage2_state_next = STAGE2_IDLE;
            end
            STAGE2_TRANSFER: begin
                if (!busy_stage2)
                    stage2_state_next = STAGE2_IDLE;
                else
                    stage2_state_next = STAGE2_TRANSFER;
            end
            default: stage2_state_next = STAGE2_IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // Output Assignments (Registered Outputs)
    // ------------------------------------------------------------------------
    reg [7:0]  rx_data_reg;
    reg        busy_reg;
    reg        done_reg;
    reg        spi_clk_reg;
    reg        spi_cs_n_reg;
    reg        spi_mosi_reg;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data_reg   <= 8'd0;
            busy_reg      <= 1'b0;
            done_reg      <= 1'b0;
            spi_clk_reg   <= 1'b0;
            spi_cs_n_reg  <= 1'b1;
            spi_mosi_reg  <= 1'b0;
        end else begin
            rx_data_reg   <= rx_data_stage2;
            busy_reg      <= busy_stage2;
            done_reg      <= done_stage2;
            spi_clk_reg   <= spi_clk_stage2;
            spi_cs_n_reg  <= spi_cs_n_stage2;
            spi_mosi_reg  <= tx_shift_stage2[7];
        end
    end

    assign rx_data   = rx_data_reg;
    assign busy      = busy_reg;
    assign done      = done_reg;
    assign spi_clk   = spi_clk_reg;
    assign spi_cs_n  = spi_cs_n_reg;
    assign spi_mosi  = spi_mosi_reg;

endmodule