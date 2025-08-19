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

    // Stage 1: SPI clock and chip select synchronization
    reg  [1:0] spi_clk_sync_stage;
    reg        spi_cs_n_sync_stage;

    wire spi_clk_rising_edge_stage1;
    assign spi_clk_rising_edge_stage1 = (spi_clk_sync_stage[0] & ~spi_clk_sync_stage[1]);

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_clk_sync_stage <= 2'b00;
            spi_cs_n_sync_stage <= 1'b1;
        end else begin
            spi_clk_sync_stage <= {spi_clk_sync_stage[0], spi_clk};
            spi_cs_n_sync_stage <= spi_cs_n;
        end
    end

    // Stage 2: Edge detection and transfer state pipeline
    reg        spi_cs_n_prev_stage2;
    reg        transfer_active_stage2;
    reg  [2:0] bit_counter_stage2;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            spi_cs_n_prev_stage2     <= 1'b1;
            transfer_active_stage2   <= 1'b0;
            bit_counter_stage2       <= 3'h0;
        end else begin
            spi_cs_n_prev_stage2 <= spi_cs_n_sync_stage;

            // Transfer start detection
            if (spi_cs_n_prev_stage2 && !spi_cs_n_sync_stage) begin
                transfer_active_stage2 <= 1'b1;
                bit_counter_stage2     <= 3'h7;
            end
            // Transfer end detection
            else if (!spi_cs_n_prev_stage2 && spi_cs_n_sync_stage) begin
                transfer_active_stage2 <= 1'b0;
            end
            // Bit counter decrement during transfer
            else if (transfer_active_stage2 && spi_clk_rising_edge_stage1) begin
                if (bit_counter_stage2 == 3'h0)
                    bit_counter_stage2 <= 3'h7;
                else
                    bit_counter_stage2 <= bit_counter_stage2 - 1;
            end
        end
    end

    // Stage 3: Data shift register pipeline
    reg  [7:0] rx_shift_reg_stage3;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_shift_reg_stage3 <= 8'h00;
        end else begin
            if (transfer_active_stage2 && spi_clk_rising_edge_stage1) begin
                rx_shift_reg_stage3 <= {rx_shift_reg_stage3[6:0], spi_mosi};
            end
        end
    end

    // Stage 4: Output register and valid flag
    reg        rx_valid_stage4;
    reg  [7:0] rx_data_stage4;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data_stage4  <= 8'h00;
            rx_valid_stage4 <= 1'b0;
        end else begin
            rx_valid_stage4 <= 1'b0;
            // Latch data and set valid when transfer ends
            if (!spi_cs_n_prev_stage2 && spi_cs_n_sync_stage) begin
                rx_data_stage4  <= rx_shift_reg_stage3;
                rx_valid_stage4 <= 1'b1;
            end
        end
    end

    // Output assignment
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_data  <= 8'h00;
            rx_valid <= 1'b0;
        end else begin
            rx_data  <= rx_data_stage4;
            rx_valid <= rx_valid_stage4;
        end
    end

endmodule