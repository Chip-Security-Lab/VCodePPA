//SystemVerilog
module spi_master_configurable (
    input         clock,
    input         reset,
    input         cpol,
    input         cpha,
    input         enable,
    input         load,
    input  [7:0]  tx_data,
    output [7:0]  rx_data,
    output        spi_clk,
    output        spi_mosi,
    input         spi_miso,
    output        cs_n,
    output        tx_ready
);

// Internal signals and registers
reg  [7:0] tx_shift_stage1, tx_shift_stage2, tx_shift_stage3;
reg  [7:0] rx_shift_stage1, rx_shift_stage2, rx_shift_stage3;
reg  [3:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
reg        sclk_internal_stage1, sclk_internal_stage2, sclk_internal_stage3;
reg        tx_ready_stage1, tx_ready_stage2, tx_ready_stage3;
reg        sclk_toggle_stage1, sclk_toggle_stage2, sclk_toggle_stage3;

// Pipeline registers for CPHA and SCLK phase evaluation (deeper pipeline)
reg        sclk_phase_eval_stage1, sclk_phase_eval_stage2, sclk_phase_eval_stage3;
reg        cpha_stage1, cpha_stage2, cpha_stage3;
reg        spi_miso_sampled_stage1, spi_miso_sampled_stage2;
reg        miso_shift_enable_stage1, miso_shift_enable_stage2, miso_shift_enable_stage3;
reg        mosi_shift_enable_stage1, mosi_shift_enable_stage2, mosi_shift_enable_stage3;

// Output assignments
assign spi_clk   = (cpol) ? ~sclk_internal_stage3 : sclk_internal_stage3;
assign spi_mosi  = tx_shift_stage3[7];
assign rx_data   = rx_shift_stage3;
assign tx_ready  = tx_ready_stage3;
assign cs_n      = ~enable;

// Pipeline CPHA and phase calculation (deeper pipeline)
always @(posedge clock or posedge reset) begin
    if (reset) begin
        cpha_stage1               <= 1'b0;
        cpha_stage2               <= 1'b0;
        cpha_stage3               <= 1'b0;
        sclk_phase_eval_stage1    <= 1'b0;
        sclk_phase_eval_stage2    <= 1'b0;
        sclk_phase_eval_stage3    <= 1'b0;
    end else begin
        cpha_stage1               <= cpha;
        cpha_stage2               <= cpha_stage1;
        cpha_stage3               <= cpha_stage2;
        sclk_phase_eval_stage1    <= sclk_internal_stage1;
        sclk_phase_eval_stage2    <= sclk_phase_eval_stage1;
        sclk_phase_eval_stage3    <= sclk_phase_eval_stage2;
    end
end

// SPI MISO input sampling pipeline (2-stage)
always @(posedge clock) begin
    spi_miso_sampled_stage1      <= spi_miso;
    spi_miso_sampled_stage2      <= spi_miso_sampled_stage1;
end

// Control logic and pipeline for shifting enables (deeper pipeline)
always @(posedge clock or posedge reset) begin
    if (reset) begin
        tx_shift_stage1          <= 8'h00;
        tx_shift_stage2          <= 8'h00;
        tx_shift_stage3          <= 8'h00;
        rx_shift_stage1          <= 8'h00;
        rx_shift_stage2          <= 8'h00;
        rx_shift_stage3          <= 8'h00;
        bit_count_stage1         <= 4'd0;
        bit_count_stage2         <= 4'd0;
        bit_count_stage3         <= 4'd0;
        sclk_internal_stage1     <= 1'b0;
        sclk_internal_stage2     <= 1'b0;
        sclk_internal_stage3     <= 1'b0;
        tx_ready_stage1          <= 1'b1;
        tx_ready_stage2          <= 1'b1;
        tx_ready_stage3          <= 1'b1;
        sclk_toggle_stage1       <= 1'b0;
        sclk_toggle_stage2       <= 1'b0;
        sclk_toggle_stage3       <= 1'b0;
        miso_shift_enable_stage1 <= 1'b0;
        miso_shift_enable_stage2 <= 1'b0;
        miso_shift_enable_stage3 <= 1'b0;
        mosi_shift_enable_stage1 <= 1'b0;
        mosi_shift_enable_stage2 <= 1'b0;
        mosi_shift_enable_stage3 <= 1'b0;
    end else begin
        // Stage 1: Input and control signals
        if (load && tx_ready_stage3) begin
            tx_shift_stage1          <= tx_data;
            rx_shift_stage1          <= 8'h00;
            bit_count_stage1         <= 4'd8;
            sclk_internal_stage1     <= 1'b0;
            tx_ready_stage1          <= 1'b0;
            sclk_toggle_stage1       <= 1'b0;
            miso_shift_enable_stage1 <= 1'b0;
            mosi_shift_enable_stage1 <= 1'b0;
        end else if (!tx_ready_stage3) begin
            // Toggle SPI clock
            sclk_internal_stage1     <= ~sclk_internal_stage3;
            sclk_toggle_stage1       <= ~sclk_toggle_stage3;

            // Evaluate phase for RX shift (pipeline)
            if ((sclk_phase_eval_stage3 && !cpha_stage3) || (!sclk_phase_eval_stage3 && cpha_stage3)) begin
                miso_shift_enable_stage1 <= 1'b1;
            end else begin
                miso_shift_enable_stage1 <= 1'b0;
            end

            // Evaluate phase for TX shift (pipeline)
            if ((~sclk_phase_eval_stage3 && !cpha_stage3) || (sclk_phase_eval_stage3 && cpha_stage3)) begin
                mosi_shift_enable_stage1 <= 1'b1;
            end else begin
                mosi_shift_enable_stage1 <= 1'b0;
            end

            // RX shift pipeline stage 1
            if (miso_shift_enable_stage3) begin
                rx_shift_stage1 <= {rx_shift_stage3[6:0], spi_miso_sampled_stage2};
            end else begin
                rx_shift_stage1 <= rx_shift_stage3;
            end

            // TX shift pipeline stage 1 and update counter
            if (mosi_shift_enable_stage3) begin
                tx_shift_stage1      <= {tx_shift_stage3[6:0], 1'b0};
                bit_count_stage1     <= bit_count_stage3 - 4'd1;
                if (bit_count_stage3 == 4'd1)
                    tx_ready_stage1  <= 1'b1;
                else
                    tx_ready_stage1  <= 1'b0;
            end else begin
                tx_shift_stage1      <= tx_shift_stage3;
                bit_count_stage1     <= bit_count_stage3;
                tx_ready_stage1      <= tx_ready_stage3;
            end
        end else begin
            tx_shift_stage1          <= tx_shift_stage3;
            rx_shift_stage1          <= rx_shift_stage3;
            bit_count_stage1         <= bit_count_stage3;
            sclk_internal_stage1     <= sclk_internal_stage3;
            tx_ready_stage1          <= tx_ready_stage3;
            sclk_toggle_stage1       <= sclk_toggle_stage3;
            miso_shift_enable_stage1 <= 1'b0;
            mosi_shift_enable_stage1 <= 1'b0;
        end

        // Stage 2: Pipeline intermediate registers
        tx_shift_stage2          <= tx_shift_stage1;
        rx_shift_stage2          <= rx_shift_stage1;
        bit_count_stage2         <= bit_count_stage1;
        sclk_internal_stage2     <= sclk_internal_stage1;
        tx_ready_stage2          <= tx_ready_stage1;
        sclk_toggle_stage2       <= sclk_toggle_stage1;
        miso_shift_enable_stage2 <= miso_shift_enable_stage1;
        mosi_shift_enable_stage2 <= mosi_shift_enable_stage1;

        // Stage 3: Output registers
        tx_shift_stage3          <= tx_shift_stage2;
        rx_shift_stage3          <= rx_shift_stage2;
        bit_count_stage3         <= bit_count_stage2;
        sclk_internal_stage3     <= sclk_internal_stage2;
        tx_ready_stage3          <= tx_ready_stage2;
        sclk_toggle_stage3       <= sclk_toggle_stage2;
        miso_shift_enable_stage3 <= miso_shift_enable_stage2;
        mosi_shift_enable_stage3 <= mosi_shift_enable_stage2;
    end
end

endmodule