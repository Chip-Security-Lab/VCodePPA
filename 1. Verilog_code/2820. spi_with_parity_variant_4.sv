//SystemVerilog
`timescale 1ns / 1ps
module spi_with_parity_axi_stream #(
    parameter DATA_WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    // AXI-Stream Slave (input) for TX
    input  [DATA_WIDTH-1:0] s_axis_tdata,
    input                   s_axis_tvalid,
    output                  s_axis_tready,
    // AXI-Stream Master (output) for RX
    output [DATA_WIDTH-1:0] m_axis_tdata,
    output                  m_axis_tvalid,
    input                   m_axis_tready,
    output                  m_axis_tlast,
    output                  parity_error,
    // SPI interface
    output                  sclk,
    output                  ss_n,
    output                  mosi,
    input                   miso
);

    // ===========================================
    // Pipeline Stage 1: Input Latch & Parity
    // ===========================================
    reg  [DATA_WIDTH-1:0]   tx_data_stage1;
    reg                     tx_parity_stage1;
    reg                     tx_valid_stage1;
    wire                    tx_ready_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_stage1     <= {DATA_WIDTH{1'b0}};
            tx_parity_stage1   <= 1'b0;
            tx_valid_stage1    <= 1'b0;
        end else begin
            if (s_axis_tvalid && tx_ready_stage1) begin
                tx_data_stage1   <= s_axis_tdata;
                tx_parity_stage1 <= ^s_axis_tdata;
                tx_valid_stage1  <= 1'b1;
            end else if (tx_valid_stage1 && tx_ready_stage1) begin
                tx_valid_stage1  <= 1'b0;
            end
        end
    end

    assign tx_ready_stage1 = ~tx_valid_stage1 || (spi_tx_ready && ~busy);

    // ===========================================
    // Pipeline Stage 2: SPI TX/RX Shift Register
    // ===========================================
    reg  [DATA_WIDTH:0]     tx_shift_reg_stage2;
    reg  [DATA_WIDTH:0]     rx_shift_reg_stage2;
    reg  [3:0]              spi_bit_count_stage2;
    reg                     busy;
    reg                     sclk_stage2;
    reg                     spi_tx_valid;
    reg                     spi_tx_ready;
    reg                     spi_rx_done;
    reg                     s_axis_tready_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg_stage2    <= { (DATA_WIDTH+1) {1'b0} };
            rx_shift_reg_stage2    <= { (DATA_WIDTH+1) {1'b0} };
            spi_bit_count_stage2   <= 4'd0;
            busy                   <= 1'b0;
            sclk_stage2            <= 1'b0;
            spi_tx_valid           <= 1'b0;
            spi_tx_ready           <= 1'b1;
            spi_rx_done            <= 1'b0;
            s_axis_tready_r        <= 1'b1;
        end else begin
            spi_rx_done            <= 1'b0;

            // Default to ready unless busy
            if (busy) begin
                s_axis_tready_r    <= 1'b0;
                spi_tx_ready       <= 1'b0;
            end else begin
                s_axis_tready_r    <= 1'b1;
                spi_tx_ready       <= 1'b1;
            end

            if (busy) begin
                sclk_stage2 <= ~sclk_stage2;
                if (sclk_stage2) begin // Falling edge: shift out TX
                    tx_shift_reg_stage2 <= {tx_shift_reg_stage2[DATA_WIDTH-1:0], 1'b0};
                    if (spi_bit_count_stage2 == 4'd0) begin
                        busy <= 1'b0;
                        spi_rx_done <= 1'b1;
                    end
                end else begin // Rising edge: shift in RX
                    rx_shift_reg_stage2 <= {rx_shift_reg_stage2[DATA_WIDTH-1:0], miso};
                    spi_bit_count_stage2 <= spi_bit_count_stage2 - 4'd1;
                end
            end else begin
                sclk_stage2 <= 1'b0;
                if (tx_valid_stage1 && spi_tx_ready) begin
                    tx_shift_reg_stage2  <= {tx_data_stage1, tx_parity_stage1};
                    spi_bit_count_stage2 <= 4'd9;
                    busy                 <= 1'b1;
                    spi_rx_done          <= 1'b0;
                end
            end
        end
    end

    // ===========================================
    // Pipeline Stage 3: Output Latch & Parity Check
    // ===========================================
    reg  [DATA_WIDTH-1:0]   m_axis_tdata_stage3;
    reg                     m_axis_tvalid_stage3;
    reg                     m_axis_tlast_stage3;
    reg                     parity_error_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata_stage3    <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid_stage3   <= 1'b0;
            m_axis_tlast_stage3    <= 1'b0;
            parity_error_stage3    <= 1'b0;
        end else begin
            if (spi_rx_done) begin
                m_axis_tdata_stage3  <= rx_shift_reg_stage2[DATA_WIDTH-1:0];
                m_axis_tvalid_stage3 <= 1'b1;
                m_axis_tlast_stage3  <= 1'b1;
                parity_error_stage3  <= (^rx_shift_reg_stage2[DATA_WIDTH-1:0] != rx_shift_reg_stage2[DATA_WIDTH]);
            end else if (m_axis_tvalid_stage3 && m_axis_tready) begin
                m_axis_tvalid_stage3 <= 1'b0;
                m_axis_tlast_stage3  <= 1'b0;
                parity_error_stage3  <= 1'b0;
            end
        end
    end

    // ===========================================
    // Output Assignments
    // ===========================================
    assign sclk            = busy ? sclk_stage2 : 1'b0;
    assign ss_n            = ~busy;
    assign mosi            = tx_shift_reg_stage2[DATA_WIDTH];
    assign s_axis_tready   = s_axis_tready_r;
    assign m_axis_tdata    = m_axis_tdata_stage3;
    assign m_axis_tvalid   = m_axis_tvalid_stage3;
    assign m_axis_tlast    = m_axis_tlast_stage3;
    assign parity_error    = parity_error_stage3;

endmodule