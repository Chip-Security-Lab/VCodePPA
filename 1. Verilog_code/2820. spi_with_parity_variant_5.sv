//SystemVerilog
// Top-level SPI with Parity Module using AXI-Stream Interface
module spi_with_parity_axi_stream(
    input  wire         clk,
    input  wire         rst_n,
    // AXI-Stream Slave Interface (input data stream)
    input  wire [7:0]   s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    // AXI-Stream Master Interface (output data stream)
    output wire [7:0]   m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast,
    output wire         m_axis_tuser, // Parity error status
    // SPI signals
    output wire         sclk,
    output wire         ss_n,
    output wire         mosi,
    input  wire         miso
);

    // Internal signals
    wire        spi_busy;
    wire        spi_done;
    wire [8:0]  spi_tx_shift;
    wire [8:0]  spi_rx_shift;
    wire        spi_sclk;
    wire [3:0]  spi_bit_count;
    wire        parity_bit;

    reg         tx_start_reg;
    reg  [7:0]  tx_data_reg;
    reg         tx_parity_reg;

    // AXI-Stream handshake for input
    assign s_axis_tready = ~spi_busy && ~tx_start_reg;

    // Latch input data on valid/ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_reg    <= 8'd0;
            tx_parity_reg  <= 1'b0;
            tx_start_reg   <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            tx_data_reg    <= s_axis_tdata;
            tx_parity_reg  <= ^s_axis_tdata;
            tx_start_reg   <= 1'b1;
        end else if (tx_start_reg && !spi_busy) begin
            tx_start_reg   <= 1'b0;
        end
    end

    // Parity Generation (combinational)
    assign parity_bit = tx_parity_reg;

    // SPI Shift and Control Submodule
    spi_shift_ctrl u_spi_shift_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data_reg),
        .tx_parity(parity_bit),
        .tx_start(tx_start_reg),
        .miso(miso),
        .busy(spi_busy),
        .done(spi_done),
        .tx_shift(spi_tx_shift),
        .rx_shift(spi_rx_shift),
        .bit_count(spi_bit_count),
        .sclk(spi_sclk)
    );

    // Output FIFO for AXI-Stream Master
    reg         rx_valid_reg;
    reg  [7:0]  rx_data_reg;
    reg         parity_error_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_reg      <= 1'b0;
            rx_data_reg       <= 8'd0;
            parity_error_reg  <= 1'b0;
        end else begin
            if (spi_done) begin
                rx_data_reg      <= spi_rx_shift[7:0];
                parity_error_reg <= (^spi_rx_shift[7:0] != spi_rx_shift[8]);
                rx_valid_reg     <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                rx_valid_reg     <= 1'b0;
            end
        end
    end

    assign m_axis_tdata  = rx_data_reg;
    assign m_axis_tvalid = rx_valid_reg;
    assign m_axis_tlast  = rx_valid_reg; // Each SPI transfer is a packet
    assign m_axis_tuser  = parity_error_reg;

    // SPI Output Logic
    assign sclk = spi_busy ? spi_sclk : 1'b0;
    assign ss_n = ~spi_busy;
    assign mosi = spi_tx_shift[8];

endmodule

// SPI Shift and Control Module
// Manages SPI shifting, bit counter, and clock toggling
module spi_shift_ctrl(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  tx_data,
    input  wire        tx_parity,
    input  wire        tx_start,
    input  wire        miso,
    output reg         busy,
    output reg         done,
    output reg  [8:0]  tx_shift,
    output reg  [8:0]  rx_shift,
    output reg  [3:0]  bit_count,
    output reg         sclk
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift  <= 9'h000;
            rx_shift  <= 9'h000;
            bit_count <= 4'h0;
            busy      <= 1'b0;
            done      <= 1'b0;
            sclk      <= 1'b0;
        end else if (tx_start && !busy) begin
            tx_shift  <= {tx_data, tx_parity};
            rx_shift  <= 9'h000;
            bit_count <= 4'd9; // 8 data bits + 1 parity
            busy      <= 1'b1;
            done      <= 1'b0;
            sclk      <= 1'b0;
        end else if (busy) begin
            sclk <= ~sclk;
            if (sclk) begin // Falling edge
                tx_shift <= {tx_shift[7:0], 1'b0};
                if (bit_count == 4'd0) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end else begin // Rising edge
                rx_shift  <= {rx_shift[7:0], miso};
                bit_count <= bit_count - 4'd1;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule