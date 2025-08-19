//SystemVerilog
// spi_master_apb.v
module spi_master_apb(
    input wire         pclk, 
    input wire         preset_n,
    
    // APB interface
    input wire  [31:0] paddr,
    input wire         psel, 
    input wire         penable, 
    input wire         pwrite,
    input wire  [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    output wire        pslverr,
    
    // SPI interface
    output wire        spi_clk,
    output wire        spi_cs_n,
    output wire        spi_mosi,
    input  wire        spi_miso,
    
    // Interrupt
    output wire        spi_irq
);

    // Internal register wires
    wire [31:0] ctrl_reg;
    wire [31:0] status_reg;
    wire [31:0] data_reg;
    wire [31:0] div_reg;
    wire        busy;
    wire        spi_clk_int;
    wire [7:0]  tx_shift;
    wire [7:0]  rx_shift;
    wire [2:0]  bit_count;

    // APB Interface submodule
    apb_interface #(
        .CTRL_REG_ADDR  (8'h00),
        .STATUS_REG_ADDR(8'h04),
        .DATA_REG_ADDR  (8'h08),
        .DIV_REG_ADDR   (8'h0C)
    ) u_apb_interface (
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
        .ctrl_reg       (ctrl_reg),
        .status_reg     (status_reg),
        .data_reg       (data_reg),
        .div_reg        (div_reg),
        .busy           (busy),
        .rx_shift       (rx_shift),
        .tx_shift       (tx_shift)
    );

    // SPI Control Logic submodule
    spi_ctrl #(
        .CTRL_REG_WIDTH   (32),
        .STATUS_REG_WIDTH (32),
        .DATA_REG_WIDTH   (32),
        .DIV_REG_WIDTH    (32)
    ) u_spi_ctrl (
        .pclk           (pclk),
        .preset_n       (preset_n),
        .ctrl_reg       (ctrl_reg),
        .status_reg     (status_reg),
        .data_reg       (data_reg),
        .div_reg        (div_reg),
        .busy           (busy),
        .spi_clk_int    (spi_clk_int),
        .tx_shift       (tx_shift),
        .rx_shift       (rx_shift),
        .bit_count      (bit_count),
        .spi_clk        (spi_clk),
        .spi_cs_n       (spi_cs_n),
        .spi_mosi       (spi_mosi),
        .spi_miso       (spi_miso)
    );

    // SPI Interrupt Logic submodule
    spi_irq_logic u_spi_irq_logic (
        .status_reg     (status_reg),
        .ctrl_reg       (ctrl_reg),
        .spi_irq        (spi_irq)
    );

endmodule

// -----------------------------------------------------------------------------
// APB Interface Submodule
// Handles all APB bus protocol, register read/write and register storage
// -----------------------------------------------------------------------------
module apb_interface #(
    parameter CTRL_REG_ADDR   = 8'h00,
    parameter STATUS_REG_ADDR = 8'h04,
    parameter DATA_REG_ADDR   = 8'h08,
    parameter DIV_REG_ADDR    = 8'h0C
)(
    input  wire        pclk,
    input  wire        preset_n,
    input  wire [31:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,
    output wire        pslverr,

    output reg  [31:0] ctrl_reg,
    output reg  [31:0] status_reg,
    output reg  [31:0] data_reg,
    output reg  [31:0] div_reg,
    input  wire        busy,
    input  wire [7:0]  rx_shift,
    output reg  [7:0]  tx_shift
);

    // Always ready and no error for APB
    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    // APB Write Operation
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            ctrl_reg    <= 32'b0;
            status_reg  <= 32'b0;
            data_reg    <= 32'b0;
            div_reg     <= 32'd2;
            tx_shift    <= 8'b0;
        end else if (psel && penable && pwrite) begin
            case (paddr[7:0])
                CTRL_REG_ADDR:   ctrl_reg   <= pwdata;
                STATUS_REG_ADDR: status_reg <= status_reg; // Read-only
                DATA_REG_ADDR: begin
                    data_reg <= pwdata;
                    tx_shift <= pwdata[7:0];
                end
                DIV_REG_ADDR:    div_reg    <= pwdata;
                default: ;
            endcase
        end
    end

    // APB Read Operation
    always @(*) begin
        case (paddr[7:0])
            CTRL_REG_ADDR:   prdata = ctrl_reg;
            STATUS_REG_ADDR: prdata = status_reg;
            DATA_REG_ADDR:   prdata = {24'b0, rx_shift};
            DIV_REG_ADDR:    prdata = div_reg;
            default:         prdata = 32'b0;
        endcase
    end

endmodule

// -----------------------------------------------------------------------------
// SPI Control Logic Submodule
// Handles SPI state machine, bit shifting, clock generation and busy logic
// -----------------------------------------------------------------------------
module spi_ctrl #(
    parameter CTRL_REG_WIDTH   = 32,
    parameter STATUS_REG_WIDTH = 32,
    parameter DATA_REG_WIDTH   = 32,
    parameter DIV_REG_WIDTH    = 32
)(
    input  wire                 pclk,
    input  wire                 preset_n,
    input  wire [CTRL_REG_WIDTH-1:0]   ctrl_reg,
    output reg  [STATUS_REG_WIDTH-1:0] status_reg,
    input  wire [DATA_REG_WIDTH-1:0]   data_reg,
    input  wire [DIV_REG_WIDTH-1:0]    div_reg,
    output reg                         busy,
    output reg                         spi_clk_int,
    input  wire [7:0]                  tx_shift,
    output reg  [7:0]                  rx_shift,
    output reg  [2:0]                  bit_count,
    output wire                        spi_clk,
    output wire                        spi_cs_n,
    output wire                        spi_mosi,
    input  wire                        spi_miso
);

    // Divider Counter for SPI clock
    reg [15:0] clk_div_cnt;

    // SPI state machine
    reg [1:0] state;
    localparam IDLE  = 2'b00;
    localparam TRANS = 2'b01;
    localparam DONE  = 2'b10;

    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;

    // SPI clock generation and state machine
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            state        <= IDLE;
            busy         <= 1'b0;
            spi_clk_int  <= 1'b0;
            clk_div_cnt  <= 16'd0;
            tx_shift_reg <= 8'b0;
            rx_shift_reg <= 8'b0;
            bit_count    <= 3'd0;
            status_reg   <= 32'b0;
            rx_shift     <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy        <= 1'b0;
                    spi_clk_int <= 1'b0;
                    clk_div_cnt <= 16'd0;
                    bit_count   <= 3'd0;
                    if (ctrl_reg[0]) begin // Enable and start
                        state        <= TRANS;
                        busy         <= 1'b1;
                        tx_shift_reg <= tx_shift;
                        rx_shift_reg <= 8'b0;
                        bit_count    <= 3'd7;
                        status_reg[0]<= 1'b0; // tx done = 0
                    end
                end
                TRANS: begin
                    busy <= 1'b1;
                    if (clk_div_cnt >= div_reg[15:0]) begin
                        clk_div_cnt <= 16'd0;
                        spi_clk_int <= ~spi_clk_int;
                        if (spi_clk_int == 1'b1) begin // On falling edge, sample
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                            if (bit_count == 0) begin
                                state      <= DONE;
                                status_reg[0] <= 1'b1; // tx done
                                rx_shift   <= {rx_shift_reg[6:0], spi_miso};
                            end else begin
                                bit_count <= bit_count - 1'b1;
                            end
                        end else begin // On rising edge, shift out next bit
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                    end else begin
                        clk_div_cnt <= clk_div_cnt + 1'b1;
                    end
                end
                DONE: begin
                    busy        <= 1'b0;
                    spi_clk_int <= 1'b0;
                    state       <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign spi_clk  = busy & spi_clk_int;
    assign spi_cs_n = ~busy;
    assign spi_mosi = tx_shift_reg[7];

endmodule

// -----------------------------------------------------------------------------
// SPI Interrupt Logic Submodule
// Handles SPI interrupt generation logic
// -----------------------------------------------------------------------------
module spi_irq_logic(
    input  wire [31:0] status_reg,
    input  wire [31:0] ctrl_reg,
    output wire        spi_irq
);
    // tx done & tx irq enable
    assign spi_irq = status_reg[0] & ctrl_reg[8];
endmodule