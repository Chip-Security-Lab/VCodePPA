//SystemVerilog
module spi_multiple_slave #(
    parameter SLAVE_COUNT = 4,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] tx_data,
    input wire [$clog2(SLAVE_COUNT)-1:0] slave_select,
    input wire start_transfer,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg transfer_done,

    output wire spi_clk,
    output reg [SLAVE_COUNT-1:0] spi_cs_n,
    output wire spi_mosi,
    input wire [SLAVE_COUNT-1:0] spi_miso
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    reg flush_stage1, flush_stage2, flush_stage3;

    // Stage 1: Capture input and generate CS
    reg [DATA_WIDTH-1:0] tx_data_stage1;
    reg [$clog2(SLAVE_COUNT)-1:0] slave_select_stage1;
    reg [SLAVE_COUNT-1:0] cs_n_stage1;
    reg [DATA_WIDTH-1:0] shift_reg_stage1;
    reg [$clog2(DATA_WIDTH):0] bit_count_stage1;
    reg start_transfer_stage1;

    // Stage 2: Shift and sample MISO
    reg [DATA_WIDTH-1:0] shift_reg_stage2;
    reg [$clog2(DATA_WIDTH):0] bit_count_stage2;
    reg [SLAVE_COUNT-1:0] cs_n_stage2;
    reg active_miso_stage2;
    reg spi_clk_d_stage2;
    reg slave_selected_stage2;
    reg [$clog2(SLAVE_COUNT)-1:0] slave_select_stage2;

    // Stage 3: Output and done signal
    reg [DATA_WIDTH-1:0] rx_data_stage3;
    reg transfer_done_stage3;

    // Busy signal (pipelined)
    reg busy_stage1, busy_stage2, busy_stage3;

    // SPI clock signals (pipelined)
    reg spi_clk_stage1, spi_clk_stage2, spi_clk_stage3;
    wire spi_clk_rising_stage2;

    // MOSI signal
    wire spi_mosi_wire;
    assign spi_mosi = spi_mosi_wire;

    // Selected slave logic (pipelined)
    wire [SLAVE_COUNT-1:0] selected_slave_wire;
    assign selected_slave_wire = (SLAVE_COUNT == 1) ? 1'b1 : (1'b1 << slave_select);

    // Active MISO selection (combinational for Stage 2)
    wire active_miso_wire_stage2;
    assign active_miso_wire_stage2 = |(spi_miso & ((SLAVE_COUNT == 1) ? 1'b1 : (1'b1 << slave_select_stage2)));

    // SPI clock generation
    assign spi_clk = busy_stage2 ? clk : 1'b0;
    assign spi_mosi_wire = shift_reg_stage2[DATA_WIDTH-1];

    // SPI clock edge detection (Stage 2)
    assign spi_clk_rising_stage2 = (spi_clk_stage2 == 1'b1) && (spi_clk_d_stage2 == 1'b0);

    // Pipeline Stage 1: Input Registering and CS Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_stage1        <= {DATA_WIDTH{1'b0}};
            slave_select_stage1   <= {($clog2(SLAVE_COUNT)){1'b0}};
            cs_n_stage1           <= {SLAVE_COUNT{1'b1}};
            shift_reg_stage1      <= {DATA_WIDTH{1'b0}};
            bit_count_stage1      <= {($clog2(DATA_WIDTH)+1){1'b0}};
            start_transfer_stage1 <= 1'b0;
            valid_stage1          <= 1'b0;
            flush_stage1          <= 1'b0;
            busy_stage1           <= 1'b0;
            spi_clk_stage1        <= 1'b0;
        end else begin
            if (flush_stage1) begin
                valid_stage1   <= 1'b0;
                busy_stage1    <= 1'b0;
                spi_clk_stage1 <= 1'b0;
            end else if (start_transfer && !busy_stage1) begin
                tx_data_stage1        <= tx_data;
                slave_select_stage1   <= slave_select;
                cs_n_stage1           <= ~selected_slave_wire;
                shift_reg_stage1      <= tx_data;
                bit_count_stage1      <= DATA_WIDTH[$clog2(DATA_WIDTH):0];
                start_transfer_stage1 <= 1'b1;
                valid_stage1          <= 1'b1;
                busy_stage1           <= 1'b1;
                spi_clk_stage1        <= 1'b1;
            end else if (busy_stage1) begin
                valid_stage1   <= valid_stage1;
                busy_stage1    <= busy_stage1;
                spi_clk_stage1 <= spi_clk_stage1;
            end else begin
                valid_stage1   <= 1'b0;
                busy_stage1    <= 1'b0;
                spi_clk_stage1 <= 1'b0;
            end
            flush_stage1 <= ~rst_n;
        end
    end

    // Pipeline Stage 2: Shift and Sample MISO
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2    <= {DATA_WIDTH{1'b0}};
            bit_count_stage2    <= {($clog2(DATA_WIDTH)+1){1'b0}};
            cs_n_stage2         <= {SLAVE_COUNT{1'b1}};
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b0;
            busy_stage2         <= 1'b0;
            spi_clk_d_stage2    <= 1'b0;
            spi_clk_stage2      <= 1'b0;
            slave_select_stage2 <= {($clog2(SLAVE_COUNT)){1'b0}};
        end else begin
            if (flush_stage2) begin
                valid_stage2   <= 1'b0;
                busy_stage2    <= 1'b0;
                spi_clk_stage2 <= 1'b0;
            end else if (valid_stage1) begin
                shift_reg_stage2    <= shift_reg_stage1;
                bit_count_stage2    <= bit_count_stage1;
                cs_n_stage2         <= cs_n_stage1;
                valid_stage2        <= valid_stage1;
                busy_stage2         <= busy_stage1;
                spi_clk_stage2      <= spi_clk_stage1;
                spi_clk_d_stage2    <= spi_clk_stage2;
                slave_select_stage2 <= slave_select_stage1;
            end else if (busy_stage2 && bit_count_stage2 != 0) begin
                spi_clk_d_stage2    <= spi_clk_stage2;
                if (spi_clk_rising_stage2) begin
                    shift_reg_stage2 <= {shift_reg_stage2[DATA_WIDTH-2:0], active_miso_wire_stage2};
                    bit_count_stage2 <= bit_count_stage2 - 1'b1;
                    if (bit_count_stage2 == 1) begin
                        busy_stage2    <= 1'b0;
                        valid_stage2   <= 1'b0;
                        spi_clk_stage2 <= 1'b0;
                    end
                end
            end else if (!busy_stage2) begin
                valid_stage2   <= 1'b0;
                busy_stage2    <= 1'b0;
                spi_clk_stage2 <= 1'b0;
            end
            flush_stage2 <= ~rst_n;
        end
    end

    // Pipeline Stage 3: Output and Done Signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_stage3      <= {DATA_WIDTH{1'b0}};
            transfer_done_stage3<= 1'b0;
            valid_stage3        <= 1'b0;
            flush_stage3        <= 1'b0;
            busy_stage3         <= 1'b0;
            spi_clk_stage3      <= 1'b0;
        end else begin
            if (flush_stage3) begin
                valid_stage3        <= 1'b0;
                busy_stage3         <= 1'b0;
                transfer_done_stage3<= 1'b0;
                spi_clk_stage3      <= 1'b0;
            end else if (valid_stage2 && busy_stage2 && (bit_count_stage2 == 1) && spi_clk_rising_stage2) begin
                rx_data_stage3       <= {shift_reg_stage2[DATA_WIDTH-2:0], active_miso_wire_stage2};
                transfer_done_stage3 <= 1'b1;
                valid_stage3         <= 1'b1;
                busy_stage3          <= 1'b0;
                spi_clk_stage3       <= 1'b0;
            end else begin
                transfer_done_stage3 <= 1'b0;
                valid_stage3         <= 1'b0;
                busy_stage3          <= 1'b0;
                spi_clk_stage3       <= 1'b0;
            end
            flush_stage3 <= ~rst_n;
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data        <= {DATA_WIDTH{1'b0}};
            transfer_done  <= 1'b0;
            spi_cs_n       <= {SLAVE_COUNT{1'b1}};
        end else begin
            if (transfer_done_stage3) begin
                rx_data       <= rx_data_stage3;
                transfer_done <= 1'b1;
                spi_cs_n      <= {SLAVE_COUNT{1'b1}};
            end else if (valid_stage1) begin
                spi_cs_n      <= cs_n_stage1;
                transfer_done <= 1'b0;
            end else if (valid_stage2) begin
                spi_cs_n      <= cs_n_stage2;
                transfer_done <= 1'b0;
            end else begin
                transfer_done <= 1'b0;
            end
        end
    end

endmodule