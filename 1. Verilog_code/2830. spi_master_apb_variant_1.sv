//SystemVerilog
// Top-level APB to SPI Master Controller with hierarchical structure

module spi_master_apb(
    input               pclk,
    input               preset_n,
    // APB interface
    input      [31:0]   paddr,
    input               psel,
    input               penable,
    input               pwrite,
    input      [31:0]   pwdata,
    output     [31:0]   prdata,
    output              pready,
    output              pslverr,
    // SPI interface
    output              spi_clk,
    output              spi_cs_n,
    output              spi_mosi,
    input               spi_miso,
    // Interrupt
    output              spi_irq
);

    // Internal register wires
    wire [31:0] ctrl_reg_w;
    wire [31:0] status_reg_w;
    wire [31:0] data_reg_w;
    wire [31:0] div_reg_w;

    // SPI core <-> Register file interface
    wire [7:0]  tx_data;
    wire [7:0]  rx_data;
    wire        tx_load;
    wire        rx_valid;
    wire        busy_w;
    wire        clear_status;
    wire        spi_clk_int;
    wire [2:0]  bit_count_w;

    // APB register interface signals
    wire        reg_write;
    wire        reg_read;
    wire [3:0]  reg_addr;
    wire [31:0] reg_wdata;
    wire [31:0] reg_rdata;

    // APB Interface Submodule
    apb_if u_apb_if (
        .pclk           (pclk),
        .preset_n       (preset_n),
        .paddr          (paddr),
        .psel           (psel),
        .penable        (penable),
        .pwrite         (pwrite),
        .pwdata         (pwdata),
        .prdata         (prdata),
        .pready         (pready),
        .pslverr        (pslverr),
        .reg_write      (reg_write),
        .reg_read       (reg_read),
        .reg_addr       (reg_addr),
        .reg_wdata      (reg_wdata),
        .reg_rdata      (reg_rdata)
    );

    // Register File Submodule
    spi_regfile u_regfile (
        .pclk           (pclk),
        .preset_n       (preset_n),
        .reg_write      (reg_write),
        .reg_read       (reg_read),
        .reg_addr       (reg_addr),
        .reg_wdata      (reg_wdata),
        .reg_rdata      (reg_rdata),
        .ctrl_reg       (ctrl_reg_w),
        .status_reg     (status_reg_w),
        .data_reg       (data_reg_w),
        .div_reg        (div_reg_w),
        .tx_data        (tx_data),
        .rx_data        (rx_data),
        .tx_load        (tx_load),
        .rx_valid       (rx_valid),
        .busy           (busy_w),
        .clear_status   (clear_status)
    );

    // SPI Core Submodule
    spi_core u_spi_core (
        .pclk           (pclk),
        .preset_n       (preset_n),
        .ctrl_reg       (ctrl_reg_w),
        .div_reg        (div_reg_w),
        .tx_data        (tx_data),
        .tx_load        (tx_load),
        .rx_data        (rx_data),
        .rx_valid       (rx_valid),
        .busy           (busy_w),
        .clear_status   (clear_status),
        .spi_clk_int    (spi_clk_int),
        .bit_count      (bit_count_w),
        .spi_clk        (spi_clk),
        .spi_cs_n       (spi_cs_n),
        .spi_mosi       (spi_mosi),
        .spi_miso       (spi_miso)
    );

    // Interrupt Generation Submodule
    spi_irq_gen u_irq_gen (
        .status_reg     (status_reg_w),
        .ctrl_reg       (ctrl_reg_w),
        .spi_irq        (spi_irq)
    );

endmodule

// -----------------------------------------------------------------------------
// APB Interface Submodule
// Handles APB transaction decode and provides register access interface
// -----------------------------------------------------------------------------
module apb_if(
    input           pclk,
    input           preset_n,
    input  [31:0]   paddr,
    input           psel,
    input           penable,
    input           pwrite,
    input  [31:0]   pwdata,
    output [31:0]   prdata,
    output          pready,
    output          pslverr,
    output          reg_write,
    output          reg_read,
    output [3:0]    reg_addr,
    output [31:0]   reg_wdata,
    input  [31:0]   reg_rdata
);
    // Always ready, no error
    assign pready    = 1'b1;
    assign pslverr   = 1'b0;

    assign reg_write = psel & penable & pwrite;
    assign reg_read  = psel & penable & ~pwrite;
    assign reg_addr  = paddr[3:0];
    assign reg_wdata = pwdata;

    assign prdata    = reg_rdata;
endmodule

// -----------------------------------------------------------------------------
// Register File Submodule
// Contains all APB accessible registers and synchronizes with SPI core
// -----------------------------------------------------------------------------
module spi_regfile(
    input           pclk,
    input           preset_n,
    input           reg_write,
    input           reg_read,
    input  [3:0]    reg_addr,
    input  [31:0]   reg_wdata,
    output [31:0]   reg_rdata,
    output [31:0]   ctrl_reg,
    output [31:0]   status_reg,
    output [31:0]   data_reg,
    output [31:0]   div_reg,
    output [7:0]    tx_data,
    input  [7:0]    rx_data,
    output          tx_load,
    input           rx_valid,
    input           busy,
    output          clear_status
);

    // Register addresses
    localparam CTRL_REG_ADDR   = 4'h0;
    localparam STATUS_REG_ADDR = 4'h4;
    localparam DATA_REG_ADDR   = 4'h8;
    localparam DIV_REG_ADDR    = 4'hC;

    reg [31:0] ctrl_reg_r;
    reg [31:0] status_reg_r;
    reg [31:0] data_reg_r;
    reg [31:0] div_reg_r;

    reg tx_load_r;
    reg clear_status_r;

    // Control register write
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            ctrl_reg_r <= 32'b0;
        else if (reg_write && reg_addr == CTRL_REG_ADDR)
            ctrl_reg_r <= reg_wdata;
    end

    // Divider register write
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            div_reg_r <= 32'd4; // Default divider
        else if (reg_write && reg_addr == DIV_REG_ADDR)
            div_reg_r <= reg_wdata;
    end

    // Data register write (TX)
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            data_reg_r <= 32'b0;
        else if (reg_write && reg_addr == DATA_REG_ADDR)
            data_reg_r <= reg_wdata;
        else if (rx_valid)
            data_reg_r <= {24'b0, rx_data};
    end

    // Status register logic
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            status_reg_r <= 32'b0;
        else if (clear_status_r)
            status_reg_r <= 32'b0;
        else begin
            status_reg_r[0] <= rx_valid;            // RX valid/interrupt
            status_reg_r[1] <= busy;                // Busy
            status_reg_r[2] <= ~busy;               // TX empty (ready for new data)
        end
    end

    // TX load pulse generation
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            tx_load_r <= 1'b0;
        else
            tx_load_r <= reg_write && reg_addr == DATA_REG_ADDR && ~busy;
    end

    // Clear status pulse
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            clear_status_r <= 1'b0;
        else
            clear_status_r <= reg_write && reg_addr == STATUS_REG_ADDR;
    end

    // APB Readback
    reg [31:0] reg_rdata_r;
    always @(*) begin
        case (reg_addr)
            CTRL_REG_ADDR:    reg_rdata_r = ctrl_reg_r;
            STATUS_REG_ADDR:  reg_rdata_r = status_reg_r;
            DATA_REG_ADDR:    reg_rdata_r = data_reg_r;
            DIV_REG_ADDR:     reg_rdata_r = div_reg_r;
            default:          reg_rdata_r = 32'b0;
        endcase
    end

    assign reg_rdata   = reg_rdata_r;
    assign ctrl_reg    = ctrl_reg_r;
    assign status_reg  = status_reg_r;
    assign data_reg    = data_reg_r;
    assign div_reg     = div_reg_r;
    assign tx_data     = data_reg_r[7:0];
    assign tx_load     = tx_load_r;
    assign clear_status= clear_status_r;

endmodule

// -----------------------------------------------------------------------------
// SPI Core Submodule
// Handles SPI transmission and reception logic and clock generation
// -----------------------------------------------------------------------------
module spi_core(
    input           pclk,
    input           preset_n,
    input  [31:0]   ctrl_reg,
    input  [31:0]   div_reg,
    input  [7:0]    tx_data,
    input           tx_load,
    output [7:0]    rx_data,
    output          rx_valid,
    output          busy,
    input           clear_status,
    output          spi_clk_int,
    output [2:0]    bit_count,
    output          spi_clk,
    output          spi_cs_n,
    output          spi_mosi,
    input           spi_miso
);

    // Internal SPI signals
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg [2:0] bit_cnt;
    reg       busy_r;
    reg       spi_clk_int_r;
    reg [15:0] clk_cnt;
    reg       spi_clk_r;
    reg       rx_valid_r;

    // SPI FSM states
    localparam IDLE     = 2'b00,
               LOAD     = 2'b01,
               TRANSFER = 2'b10,
               DONE     = 2'b11;

    reg [1:0] state, next_state;

    // SPI clock divider
    wire [15:0] clk_div = div_reg[15:0];

    // State machine
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE:
                if (tx_load)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            LOAD:
                next_state = TRANSFER;
            TRANSFER:
                if (bit_cnt == 3'd7 && spi_clk_int_r)
                    next_state = DONE;
                else
                    next_state = TRANSFER;
            DONE:
                next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // Shift registers and bit counter
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            tx_shift     <= 8'b0;
            rx_shift     <= 8'b0;
            bit_cnt      <= 3'b0;
            busy_r       <= 1'b0;
            spi_clk_int_r<= 1'b0;
            clk_cnt      <= 16'b0;
            spi_clk_r    <= 1'b0;
            rx_valid_r   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy_r       <= 1'b0;
                    spi_clk_int_r<= 1'b0;
                    clk_cnt      <= 16'b0;
                    spi_clk_r    <= 1'b0;
                    rx_valid_r   <= 1'b0;
                end
                LOAD: begin
                    tx_shift     <= tx_data;
                    rx_shift     <= 8'b0;
                    bit_cnt      <= 3'b0;
                    busy_r       <= 1'b1;
                    clk_cnt      <= 16'b0;
                    spi_clk_r    <= 1'b0;
                    spi_clk_int_r<= 1'b0;
                end
                TRANSFER: begin
                    busy_r       <= 1'b1;
                    if (clk_cnt == clk_div) begin
                        clk_cnt      <= 16'b0;
                        spi_clk_r    <= ~spi_clk_r;
                        spi_clk_int_r<= ~spi_clk_int_r;
                        if (spi_clk_r) begin // Sample on rising edge
                            rx_shift <= {rx_shift[6:0], spi_miso};
                            if (bit_cnt < 3'd7)
                                bit_cnt <= bit_cnt + 1'b1;
                        end else begin // Shift out on falling edge
                            tx_shift <= {tx_shift[6:0], 1'b0};
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                DONE: begin
                    busy_r       <= 1'b0;
                    rx_valid_r   <= 1'b1;
                    spi_clk_r    <= 1'b0;
                    spi_clk_int_r<= 1'b0;
                end
            endcase
            if (clear_status)
                rx_valid_r <= 1'b0;
        end
    end

    assign rx_data       = rx_shift;
    assign rx_valid      = rx_valid_r;
    assign busy          = busy_r;
    assign spi_clk_int   = spi_clk_int_r;
    assign bit_count     = bit_cnt;

    assign spi_clk       = busy_r & spi_clk_int_r;
    assign spi_cs_n      = ~busy_r;
    assign spi_mosi      = tx_shift[7];

endmodule

// -----------------------------------------------------------------------------
// Interrupt Generation Submodule
// Generates SPI IRQ signal based on status and control registers
// -----------------------------------------------------------------------------
module spi_irq_gen(
    input  [31:0]   status_reg,
    input  [31:0]   ctrl_reg,
    output          spi_irq
);
    // Interrupt: status_reg[0] (RX valid) & ctrl_reg[8] (IRQ enable)
    assign spi_irq = status_reg[0] & ctrl_reg[8];
endmodule