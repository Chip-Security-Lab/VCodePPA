//SystemVerilog
module spi_transmit_only_axi4lite #(
    parameter AXI_ADDR_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 16
)(
    input  wire                       clk,
    input  wire                       reset,

    // AXI4-Lite Slave Interface
    // Write address channel
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                       s_axi_awvalid,
    output reg                        s_axi_awready,

    // Write data channel
    input  wire [AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                       s_axi_wvalid,
    output reg                        s_axi_wready,

    // Write response channel
    output reg [1:0]                  s_axi_bresp,
    output reg                        s_axi_bvalid,
    input  wire                       s_axi_bready,

    // Read address channel
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                       s_axi_arvalid,
    output reg                        s_axi_arready,

    // Read data channel
    output reg [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]                  s_axi_rresp,
    output reg                        s_axi_rvalid,
    input  wire                       s_axi_rready,

    // SPI interface
    output wire                       spi_clk,
    output wire                       spi_cs_n,
    output wire                       spi_mosi
);

    // AXI4-Lite Registers
    reg [AXI_DATA_WIDTH-1:0] reg_tx_data;
    reg                      reg_tx_start;
    reg                      reg_tx_busy;
    reg                      reg_tx_done;

    // SPI FSM
    localparam [1:0] IDLE     = 2'b00;
    localparam [1:0] TRANSMIT = 2'b01;
    localparam [1:0] FINISH   = 2'b10;

    reg  [1:0]  cur_state, next_state;
    reg  [3:0]  bit_counter, next_bit_counter;
    reg  [15:0] data_shift, next_data_shift;
    reg         spi_clk_int, next_spi_clk_int;
    reg         next_tx_busy, next_tx_done;

    // AXI4-Lite Address Map
    localparam [AXI_ADDR_WIDTH-1:0] ADDR_TX_DATA  = 4'h0;
    localparam [AXI_ADDR_WIDTH-1:0] ADDR_TX_START = 4'h4;
    localparam [AXI_ADDR_WIDTH-1:0] ADDR_TX_BUSY  = 4'h8;
    localparam [AXI_ADDR_WIDTH-1:0] ADDR_TX_DONE  = 4'hC;

    // AXI4-Lite write FSM
    reg aw_en;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            aw_en           <= 1'b1;
        end else begin
            // Write address ready
            if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Write data ready
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Write response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                aw_en        <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end
        end
    end

    // AXI4-Lite read FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= {AXI_DATA_WIDTH{1'b0}};
        end else begin
            // Read address ready
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Read data valid
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr)
                    ADDR_TX_DATA:  s_axi_rdata <= reg_tx_data;
                    ADDR_TX_START: s_axi_rdata <= {15'd0, reg_tx_start};
                    ADDR_TX_BUSY:  s_axi_rdata <= {15'd0, reg_tx_busy};
                    ADDR_TX_DONE:  s_axi_rdata <= {15'd0, reg_tx_done};
                    default:       s_axi_rdata <= {AXI_DATA_WIDTH{1'b0}};
                endcase
                s_axi_rresp <= 2'b00;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite register write
    wire write_en = s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_tx_data  <= 16'd0;
            reg_tx_start <= 1'b0;
        end else begin
            if (write_en) begin
                case (s_axi_awaddr)
                    ADDR_TX_DATA: begin
                        if (s_axi_wstrb[1]) reg_tx_data[15:8] <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[0]) reg_tx_data[7:0]  <= s_axi_wdata[7:0];
                    end
                    ADDR_TX_START: begin
                        reg_tx_start <= s_axi_wdata[0];
                    end
                    default: ;
                endcase
            end else begin
                // Auto-clear tx_start after SPI transaction begins
                if (cur_state == TRANSMIT)
                    reg_tx_start <= 1'b0;
            end
        end
    end

    // SPI transmit FSM (core logic)
    assign spi_mosi  = data_shift[15];
    assign spi_clk   = (cur_state == TRANSMIT) ? spi_clk_int : 1'b0;
    assign spi_cs_n  = (cur_state != TRANSMIT);

    always @* begin
        // Defaults
        next_state        = cur_state;
        next_bit_counter  = bit_counter;
        next_data_shift   = data_shift;
        next_spi_clk_int  = spi_clk_int;
        next_tx_busy      = reg_tx_busy;
        next_tx_done      = reg_tx_done;

        case (cur_state)
            IDLE: begin
                next_tx_done      = 1'b0;
                next_tx_busy      = 1'b0;
                next_spi_clk_int  = 1'b0;
                if (reg_tx_start) begin
                    next_data_shift   = reg_tx_data;
                    next_bit_counter  = 4'd15;
                    next_tx_busy      = 1'b1;
                    next_state        = TRANSMIT;
                end
            end

            TRANSMIT: begin
                next_spi_clk_int = ~spi_clk_int;
                next_tx_busy     = 1'b1;
                next_tx_done     = 1'b0;
                if (!spi_clk_int) begin // falling edge
                    if (bit_counter == 4'd0) begin
                        next_state = FINISH;
                    end else begin
                        next_bit_counter = bit_counter - 1'b1;
                        next_data_shift  = {data_shift[14:0], 1'b0};
                    end
                end
            end

            FINISH: begin
                next_tx_busy     = 1'b0;
                next_tx_done     = 1'b1;
                next_spi_clk_int = 1'b0;
                next_state       = IDLE;
            end

            default: begin
                next_state        = IDLE;
                next_bit_counter  = 4'd0;
                next_data_shift   = 16'd0;
                next_spi_clk_int  = 1'b0;
                next_tx_busy      = 1'b0;
                next_tx_done      = 1'b0;
            end
        endcase
    end

    // Sequential logic for FSM and output registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cur_state     <= IDLE;
            bit_counter   <= 4'd0;
            data_shift    <= 16'd0;
            spi_clk_int   <= 1'b0;
            reg_tx_busy   <= 1'b0;
            reg_tx_done   <= 1'b0;
        end else begin
            cur_state     <= next_state;
            bit_counter   <= next_bit_counter;
            data_shift    <= next_data_shift;
            spi_clk_int   <= next_spi_clk_int;
            reg_tx_busy   <= next_tx_busy;
            reg_tx_done   <= next_tx_done;
        end
    end

endmodule