//SystemVerilog
`timescale 1ns / 1ps
module spi_master_axi_stream #(
    parameter DATA_WIDTH = 32
)(
    input wire                  clk,
    input wire                  rst_n,

    // AXI-Stream Slave Interface (for data input to SPI Master)
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire                  s_axis_tlast,

    // AXI-Stream Master Interface (for data output from SPI Master)
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire                  m_axis_tlast,

    // SPI interface
    output wire                  spi_clk,
    output wire                  spi_cs_n,
    output wire                  spi_mosi,
    input  wire                  spi_miso,

    // Interrupt
    output wire                  spi_irq
);

    // Register addresses (not used in AXI-Stream, kept for internal logic if needed)
    localparam CTRL_REG   = 8'h00;
    localparam STATUS_REG = 8'h04;
    localparam DATA_REG   = 8'h08;
    localparam DIV_REG    = 8'h0C;

    // Internal registers
    reg [31:0] ctrl_reg;     // Control: enable, interrupt mask, etc.
    reg [31:0] status_reg;   // Status: busy, tx empty, rx full, etc.
    reg [31:0] data_reg;     // Data: tx/rx data
    reg [31:0] div_reg;      // Divider: clock divider

    // SPI logic
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg [2:0] bit_counter;
    reg       spi_busy, spi_busy_next;
    reg       spi_clk_reg;
    reg       spi_cs_n_reg;
    reg       spi_mosi_reg;
    reg [7:0] tx_fifo [0:3];
    reg [7:0] rx_fifo [0:3];
    reg [1:0] tx_fifo_wr_ptr, tx_fifo_rd_ptr;
    reg [1:0] rx_fifo_wr_ptr, rx_fifo_rd_ptr;
    reg       tx_fifo_empty, tx_fifo_full;
    reg       rx_fifo_empty, rx_fifo_full;

    // AXI-Stream handshake logic
    reg  [DATA_WIDTH-1:0] tx_data_buffer;
    reg                   tx_data_buffer_valid;
    reg                   tx_data_buffer_last;
    wire                  tx_data_accept;

    reg  [DATA_WIDTH-1:0] rx_data_buffer;
    reg                   rx_data_buffer_valid;
    reg                   rx_data_buffer_last;
    wire                  rx_data_send;

    // SPI clock divider
    reg [3:0] clk_div_cnt;
    reg [3:0] clk_div_cnt_next;

    // Assign AXI-Stream handshake
    assign s_axis_tready = !tx_data_buffer_valid || (tx_data_accept && !spi_busy);
    assign tx_data_accept = s_axis_tvalid && s_axis_tready;

    assign m_axis_tdata  = rx_data_buffer;
    assign m_axis_tvalid = rx_data_buffer_valid;
    assign m_axis_tlast  = rx_data_buffer_last;
    assign rx_data_send  = m_axis_tready && rx_data_buffer_valid;

    // SPI signals
    assign spi_clk   = spi_busy ? spi_clk_reg : 1'b0;
    assign spi_cs_n  = ~spi_busy;
    assign spi_mosi  = tx_shift_reg[7];

    // Interrupt
    assign spi_irq = status_reg[0] & ctrl_reg[8]; // tx done & tx irq enable

    // TX Data Buffering (AXI-Stream input to SPI)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_buffer       <= {DATA_WIDTH{1'b0}};
            tx_data_buffer_valid <= 1'b0;
            tx_data_buffer_last  <= 1'b0;
        end else if (tx_data_accept) begin
            tx_data_buffer       <= s_axis_tdata;
            tx_data_buffer_valid <= 1'b1;
            tx_data_buffer_last  <= s_axis_tlast;
        end else if (!spi_busy && tx_data_buffer_valid) begin
            tx_data_buffer_valid <= 1'b0;
        end
    end

    // RX Data Buffering (SPI to AXI-Stream output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_buffer       <= {DATA_WIDTH{1'b0}};
            rx_data_buffer_valid <= 1'b0;
            rx_data_buffer_last  <= 1'b0;
        end else if (rx_data_send) begin
            rx_data_buffer_valid <= 1'b0;
        end else if (spi_busy == 1'b0 && status_reg[0]) begin // Transfer done
            rx_data_buffer       <= data_reg;
            rx_data_buffer_valid <= 1'b1;
            rx_data_buffer_last  <= tx_data_buffer_last;
        end
    end

    // SPI Control Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg    <= 32'b0;
            div_reg     <= 32'd4; // Default divider
        end
        // ctrl_reg and div_reg update logic can be added here if needed
    end

    // SPI Status Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg  <= 32'b0;
        end else begin
            if (tx_data_buffer_valid && !spi_busy && ctrl_reg[0]) begin
                status_reg[0] <= 1'b0; // Clear done flag
            end else if (spi_busy && bit_counter == 3'd7 && spi_clk_reg) begin
                status_reg[0] <= 1'b1; // Set done flag
            end
        end
    end

    // SPI Busy State (decoupled for clarity)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_busy <= 1'b0;
        end else begin
            if (tx_data_buffer_valid && !spi_busy && ctrl_reg[0]) begin
                spi_busy <= 1'b1;
            end else if (spi_busy && bit_counter == 3'd7 && spi_clk_reg) begin
                spi_busy <= 1'b0;
            end
        end
    end

    // SPI Shift Register and Bit Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg  <= 8'b0;
            rx_shift_reg  <= 8'b0;
            bit_counter   <= 3'd0;
            spi_cs_n_reg  <= 1'b1;
            data_reg      <= 32'b0;
        end else begin
            if (spi_busy == 1'b0 && tx_data_buffer_valid && ctrl_reg[0]) begin
                tx_shift_reg <= tx_data_buffer[7:0];
                bit_counter  <= 3'd0;
                spi_cs_n_reg <= 1'b0;
            end else if (spi_busy) begin
                if (clk_div_cnt == div_reg[3:0]) begin
                    if (spi_clk_reg) begin // Sample on rising edge
                        rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        if (bit_counter == 3'd7) begin
                            data_reg[7:0] <= rx_shift_reg;
                            spi_cs_n_reg  <= 1'b1;
                        end else begin
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_counter  <= bit_counter + 1'b1;
                        end
                    end
                end
            end else begin
                spi_cs_n_reg <= 1'b1;
            end
        end
    end

    // SPI Clock Divider and Clock Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_cnt   <= 4'd0;
            spi_clk_reg   <= 1'b0;
        end else begin
            if (spi_busy == 1'b0 && tx_data_buffer_valid && ctrl_reg[0]) begin
                clk_div_cnt <= 4'd0;
                spi_clk_reg <= 1'b0;
            end else if (spi_busy) begin
                if (clk_div_cnt == div_reg[3:0]) begin
                    clk_div_cnt <= 4'd0;
                    spi_clk_reg <= ~spi_clk_reg;
                end else begin
                    clk_div_cnt <= clk_div_cnt + 1'b1;
                end
            end
        end
    end

endmodule