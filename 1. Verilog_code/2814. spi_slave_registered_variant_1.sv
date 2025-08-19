//SystemVerilog
module spi_slave_axi_stream (
    input             clk_i,
    input             rst_i,
    input             sclk_i,
    input             cs_n_i,
    input             mosi_i,
    output            miso_o,
    input      [7:0]  axi_tx_tdata,
    input             axi_tx_tvalid,
    output            axi_tx_tready,
    output reg [7:0]  axi_rx_tdata,
    output reg        axi_rx_tvalid,
    output reg        axi_rx_tlast,
    input             axi_rx_tready
);

    // Stage 1: Edge detection pipeline
    reg sclk_r_stage1, sclk_r2_stage1;
    reg sclk_r_stage2, sclk_r2_stage2;
    wire sclk_rising_stage2, sclk_falling_stage2;

    always @(posedge clk_i) begin
        if (rst_i) begin
            sclk_r_stage1  <= 1'b0;
            sclk_r2_stage1 <= 1'b0;
        end else begin
            sclk_r_stage1  <= sclk_i;
            sclk_r2_stage1 <= sclk_r_stage1;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            sclk_r_stage2  <= 1'b0;
            sclk_r2_stage2 <= 1'b0;
        end else begin
            sclk_r_stage2  <= sclk_r_stage1;
            sclk_r2_stage2 <= sclk_r2_stage1;
        end
    end

    assign sclk_rising_stage2  =  sclk_r_stage2 & ~sclk_r2_stage2;
    assign sclk_falling_stage2 = ~sclk_r_stage2 &  sclk_r2_stage2;

    // AXI-Stream handshake for TX (slave reads data from master)
    reg [7:0] tx_data_reg;
    reg       tx_data_valid_reg;
    reg       tx_data_ready_reg;
    reg       tx_data_loaded;
    reg       load_tx_shift;
    reg [7:0] tx_shift_reg_stage2;
    reg [2:0] tx_bit_count;
    wire      tx_shift_done;

    assign axi_tx_tready = tx_data_ready_reg;

    // TX data handshake and loading logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            tx_data_reg        <= 8'h0;
            tx_data_valid_reg  <= 1'b0;
            tx_data_ready_reg  <= 1'b1;
            tx_data_loaded     <= 1'b0;
            load_tx_shift      <= 1'b0;
            tx_bit_count       <= 3'h0;
        end else begin
            load_tx_shift <= 1'b0;
            if (!cs_n_i) begin
                if (axi_tx_tvalid && axi_tx_tready && !tx_data_loaded) begin
                    tx_data_reg       <= axi_tx_tdata;
                    tx_data_valid_reg <= 1'b1;
                    tx_data_loaded    <= 1'b1;
                    tx_data_ready_reg <= 1'b0;
                    load_tx_shift     <= 1'b1;
                end else if (tx_shift_done) begin
                    tx_data_valid_reg <= 1'b0;
                    tx_data_loaded    <= 1'b0;
                    tx_data_ready_reg <= 1'b1;
                end
            end else begin
                tx_data_valid_reg <= 1'b0;
                tx_data_loaded    <= 1'b0;
                tx_data_ready_reg <= 1'b1;
            end
        end
    end

    // Stage 2: Shift logic pipeline
    reg [7:0] rx_shift_reg_stage2;
    reg [2:0] bit_count_stage2;
    reg       rx_valid_stage2;
    reg [7:0] rx_data_stage2;
    reg       cs_n_stage2;
    reg       mosi_stage2;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rx_shift_reg_stage2 <= 8'h0;
            tx_shift_reg_stage2 <= 8'h0;
            bit_count_stage2    <= 3'h0;
            rx_valid_stage2     <= 1'b0;
            rx_data_stage2      <= 8'h0;
            cs_n_stage2         <= 1'b1;
            mosi_stage2         <= 1'b0;
            tx_bit_count        <= 3'h0;
        end else begin
            cs_n_stage2    <= cs_n_i;
            mosi_stage2    <= mosi_i;

            if (!cs_n_i) begin
                // RX: Sampling data from MOSI
                if (sclk_rising_stage2) begin
                    rx_shift_reg_stage2 <= {rx_shift_reg_stage2[6:0], mosi_i};
                    bit_count_stage2    <= bit_count_stage2 + 3'h1;
                    rx_valid_stage2     <= (bit_count_stage2 == 3'h7) ? 1'b1 : 1'b0;
                    if (bit_count_stage2 == 3'h7)
                        rx_data_stage2 <= {rx_shift_reg_stage2[6:0], mosi_i};
                end else if (bit_count_stage2 == 3'h7 && rx_valid_stage2)
                    rx_valid_stage2 <= 1'b0;

                // TX: Shifting out data to MISO
                if (load_tx_shift) begin
                    tx_shift_reg_stage2 <= tx_data_reg;
                    tx_bit_count        <= 3'h0;
                end else if (sclk_falling_stage2) begin
                    tx_shift_reg_stage2 <= {tx_shift_reg_stage2[6:0], 1'b0};
                    tx_bit_count        <= tx_bit_count + 3'h1;
                end

            end else begin
                rx_valid_stage2     <= 1'b0;
                bit_count_stage2    <= 3'h0;
                tx_bit_count        <= 3'h0;
            end
        end
    end

    assign tx_shift_done = (tx_bit_count == 3'h7) && sclk_falling_stage2;

    // Stage 3: Output pipeline and AXI-Stream RX logic
    reg [7:0] rx_data_stage3;
    reg       rx_valid_stage3;
    reg       rx_tlast_stage3;
    reg       cs_n_stage3;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rx_data_stage3   <= 8'h0;
            rx_valid_stage3  <= 1'b0;
            rx_tlast_stage3  <= 1'b0;
            cs_n_stage3      <= 1'b1;
        end else begin
            rx_data_stage3  <= rx_data_stage2;
            rx_valid_stage3 <= rx_valid_stage2;
            rx_tlast_stage3 <= (!cs_n_stage2 && bit_count_stage2 == 3'h7); // TLAST on each byte
            cs_n_stage3     <= cs_n_stage2;
        end
    end

    // AXI-Stream RX handshake logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            axi_rx_tdata  <= 8'h0;
            axi_rx_tvalid <= 1'b0;
            axi_rx_tlast  <= 1'b0;
        end else begin
            if (rx_valid_stage3) begin
                if (!axi_rx_tvalid || (axi_rx_tvalid && axi_rx_tready)) begin
                    axi_rx_tdata  <= rx_data_stage3;
                    axi_rx_tvalid <= 1'b1;
                    axi_rx_tlast  <= rx_tlast_stage3;
                end
            end else if (axi_rx_tvalid && axi_rx_tready) begin
                axi_rx_tvalid <= 1'b0;
                axi_rx_tlast  <= 1'b0;
            end
        end
    end

    // Output assignments
    assign miso_o = tx_shift_reg_stage2[7];

endmodule