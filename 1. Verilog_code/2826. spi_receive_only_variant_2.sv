//SystemVerilog
module spi_receive_only(
    input  wire        spi_clk,
    input  wire        spi_cs_n,
    input  wire        spi_mosi,
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    output reg  [7:0]  rx_data,
    output reg         rx_valid
);

// === High Fanout Buffer Registers for sys_clk ===
reg sys_clk_buf1, sys_clk_buf2;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        sys_clk_buf1 <= 1'b0;
        sys_clk_buf2 <= 1'b0;
    end else begin
        sys_clk_buf1 <= 1'b1;
        sys_clk_buf2 <= sys_clk_buf1;
    end
end
wire sys_clk_local = sys_clk_buf2;

// === Stage 1: Synchronize SPI signals and detect edges ===
reg [1:0] spi_clk_sync_stage1, spi_cs_n_sync_stage1;
reg [1:0] spi_clk_sync_stage1_buf, spi_cs_n_sync_stage1_buf;
reg       spi_clk_rising_stage1, spi_cs_n_fall_stage1, spi_cs_n_rise_stage1;
reg       spi_mosi_stage1, spi_mosi_stage1_buf;
reg       b0, b0_buf; // Example for additional high fanout signal b0

// Buffer registers for high fanout SPI sync signals and data
always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        spi_clk_sync_stage1    <= 2'b00;
        spi_cs_n_sync_stage1   <= 2'b11;
        spi_mosi_stage1        <= 1'b0;
        b0                     <= 1'b0;
    end else begin
        spi_clk_sync_stage1    <= {spi_clk_sync_stage1[0], spi_clk};
        spi_cs_n_sync_stage1   <= {spi_cs_n_sync_stage1[0], spi_cs_n};
        spi_mosi_stage1        <= spi_mosi;
        b0                     <= 1'b0; // Placeholder: set as appropriate in your logic
    end
end

// Buffering high fanout signals for load balancing
always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        spi_clk_sync_stage1_buf    <= 2'b00;
        spi_cs_n_sync_stage1_buf   <= 2'b11;
        spi_mosi_stage1_buf        <= 1'b0;
        b0_buf                     <= 1'b0;
    end else begin
        spi_clk_sync_stage1_buf    <= spi_clk_sync_stage1;
        spi_cs_n_sync_stage1_buf   <= spi_cs_n_sync_stage1;
        spi_mosi_stage1_buf        <= spi_mosi_stage1;
        b0_buf                     <= b0;
    end
end

always @(*) begin
    spi_clk_rising_stage1 = (spi_clk_sync_stage1_buf[0] & ~spi_clk_sync_stage1_buf[1]);
    spi_cs_n_fall_stage1  = (spi_cs_n_sync_stage1_buf[1] & ~spi_cs_n_sync_stage1_buf[0]);
    spi_cs_n_rise_stage1  = (~spi_cs_n_sync_stage1_buf[1] & spi_cs_n_sync_stage1_buf[0]);
end

reg        spi_clk_rising_stage2, spi_cs_n_fall_stage2, spi_cs_n_rise_stage2;
reg        spi_mosi_stage2;
reg        valid_stage2;
reg        b0_stage2;

// Stage2 buffers for high fanout signals
always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        spi_clk_rising_stage2 <= 1'b0;
        spi_cs_n_fall_stage2  <= 1'b0;
        spi_cs_n_rise_stage2  <= 1'b0;
        spi_mosi_stage2       <= 1'b0;
        valid_stage2          <= 1'b0;
        b0_stage2             <= 1'b0;
    end else begin
        spi_clk_rising_stage2 <= spi_clk_rising_stage1;
        spi_cs_n_fall_stage2  <= spi_cs_n_fall_stage1;
        spi_cs_n_rise_stage2  <= spi_cs_n_rise_stage1;
        spi_mosi_stage2       <= spi_mosi_stage1_buf;
        valid_stage2          <= 1'b1;
        b0_stage2             <= b0_buf;
    end
end

// === Stage 2: Manage transfer_active, bit_count, rx_shift ===
reg        transfer_active_stage2, transfer_active_stage3;
reg [2:0]  bit_count_stage2, bit_count_stage3;
reg [7:0]  rx_shift_stage2, rx_shift_stage3;
reg        valid_stage3;
reg        rx_done_stage2, rx_done_stage3;
reg        b0_stage3;

always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        transfer_active_stage2 <= 1'b0;
        bit_count_stage2       <= 3'h0;
        rx_shift_stage2        <= 8'h00;
        rx_done_stage2         <= 1'b0;
        valid_stage3           <= 1'b0;
        b0_stage3              <= 1'b0;
    end else if (valid_stage2) begin
        // Transfer Active Management
        if (spi_cs_n_fall_stage2) begin
            transfer_active_stage2 <= 1'b1;
            bit_count_stage2       <= 3'h7;
            rx_shift_stage2        <= 8'h00;
        end else if (spi_cs_n_rise_stage2) begin
            transfer_active_stage2 <= 1'b0;
            bit_count_stage2       <= bit_count_stage2;
            rx_shift_stage2        <= rx_shift_stage2;
        end else if (transfer_active_stage2 && spi_clk_rising_stage2) begin
            transfer_active_stage2 <= transfer_active_stage2;
            rx_shift_stage2        <= {rx_shift_stage2[6:0], spi_mosi_stage2};
            if (bit_count_stage2 == 3'h0)
                bit_count_stage2 <= 3'h7;
            else
                bit_count_stage2 <= bit_count_stage2 - 1;
        end else begin
            transfer_active_stage2 <= transfer_active_stage2;
            bit_count_stage2       <= bit_count_stage2;
            rx_shift_stage2        <= rx_shift_stage2;
        end

        // Detect end of transfer for rx_done
        rx_done_stage2 <= spi_cs_n_rise_stage2;
        valid_stage3   <= valid_stage2;
        b0_stage3      <= b0_stage2;
    end else begin
        transfer_active_stage2 <= transfer_active_stage2;
        bit_count_stage2       <= bit_count_stage2;
        rx_shift_stage2        <= rx_shift_stage2;
        rx_done_stage2         <= 1'b0;
        valid_stage3           <= 1'b0;
        b0_stage3              <= b0_stage3;
    end
end

// === Stage 3: Output register update ===
reg b0_stage4;
always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        transfer_active_stage3 <= 1'b0;
        bit_count_stage3       <= 3'h0;
        rx_shift_stage3        <= 8'h00;
        rx_done_stage3         <= 1'b0;
        b0_stage4              <= 1'b0;
    end else if (valid_stage3) begin
        transfer_active_stage3 <= transfer_active_stage2;
        bit_count_stage3       <= bit_count_stage2;
        rx_shift_stage3        <= rx_shift_stage2;
        rx_done_stage3         <= rx_done_stage2;
        b0_stage4              <= b0_stage3;
    end
end

// === Stage 4: Final output (rx_data, rx_valid) ===
always @(posedge sys_clk_local or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        rx_data  <= 8'h00;
        rx_valid <= 1'b0;
    end else begin
        rx_valid <= rx_done_stage3;
        if (rx_done_stage3)
            rx_data <= rx_shift_stage3;
    end
end

endmodule