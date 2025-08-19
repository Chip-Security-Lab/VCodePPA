//SystemVerilog
module dual_mode_spi_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input wire          axi_aclk,
    input wire          axi_aresetn,

    // AXI4-Lite Write Address Channel
    input wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input wire                   s_axi_awvalid,
    output reg                   s_axi_awready,

    // AXI4-Lite Write Data Channel
    input wire [7:0]             s_axi_wdata,
    input wire [0:0]             s_axi_wstrb,
    input wire                   s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]             s_axi_bresp,
    output reg                   s_axi_bvalid,
    input wire                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input wire                   s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [7:0]             s_axi_rdata,
    output reg [1:0]             s_axi_rresp,
    output reg                   s_axi_rvalid,
    input wire                   s_axi_rready,

    // SPI IO
    output reg                   sck,
    output reg                   cs_n,
    inout                        io0,
    inout                        io1
);

    // AXI4-Lite Registers (memory-mapped)
    reg [7:0] reg_tx_data;
    reg [7:0] reg_rx_data;
    reg       reg_mode;
    reg       reg_start;
    reg       reg_done;

    // Internal SPI signals
    reg [7:0] tx_shift, rx_shift;
    reg [2:0] bit_count;
    reg       io0_out, io1_out;
    reg       io0_oe, io1_oe;
    reg       start_pulse;
    reg       spi_active;

    // Tri-state buffer control
    assign io0 = io0_oe ? io0_out : 1'bz;
    assign io1 = io1_oe ? io1_out : 1'bz;

    // AXI4-Lite FSM states
    localparam [1:0] AXI_IDLE = 2'd0,
                     AXI_WRITE = 2'd1,
                     AXI_WRITE_RESP = 2'd2,
                     AXI_READ = 2'd3;
    reg [1:0] axi_wr_state;
    reg [1:0] axi_rd_state;

    // Write address and data latching
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg [ADDR_WIDTH-1:0] araddr_latched;

    // AXI4-Lite Write Channel
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            axi_wr_state <= AXI_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            case (axi_wr_state)
                AXI_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    s_axi_bvalid  <= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        awaddr_latched <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        axi_wr_state <= AXI_WRITE;
                    end
                end
                AXI_WRITE: begin
                    // Write to registers
                    case (awaddr_latched[3:0])
                        4'h0: reg_tx_data <= s_axi_wdata;
                        4'h1: reg_mode    <= s_axi_wdata[0];
                        4'h2: begin
                            if (s_axi_wdata[0]) reg_start <= 1'b1;
                        end
                        default: ;
                    endcase
                    s_axi_bresp  <= 2'b00;
                    s_axi_bvalid <= 1'b1;
                    axi_wr_state <= AXI_WRITE_RESP;
                end
                AXI_WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        axi_wr_state <= AXI_IDLE;
                        reg_start <= 1'b0; // Clear start after write response
                    end
                end
                default: axi_wr_state <= AXI_IDLE;
            endcase
        end
    end

    // AXI4-Lite Read Channel
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            axi_rd_state <= AXI_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 8'h00;
            s_axi_rresp   <= 2'b00;
            araddr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            case (axi_rd_state)
                AXI_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    if (s_axi_arvalid) begin
                        araddr_latched <= s_axi_araddr;
                        s_axi_arready <= 1'b0;
                        axi_rd_state <= AXI_READ;
                    end
                end
                AXI_READ: begin
                    if (araddr_latched[3:0] == 4'h0) begin
                        s_axi_rdata <= reg_tx_data;
                    end else if (araddr_latched[3:0] == 4'h1) begin
                        s_axi_rdata <= {7'b0, reg_mode};
                    end else if (araddr_latched[3:0] == 4'h2) begin
                        s_axi_rdata <= {7'b0, reg_start};
                    end else if (araddr_latched[3:0] == 4'h3) begin
                        s_axi_rdata <= reg_rx_data;
                    end else if (araddr_latched[3:0] == 4'h4) begin
                        s_axi_rdata <= {7'b0, reg_done};
                    end else begin
                        s_axi_rdata <= 8'h00;
                    end
                    s_axi_rresp  <= 2'b00;
                    s_axi_rvalid <= 1'b1;
                    axi_rd_state <= AXI_WRITE_RESP;
                end
                AXI_WRITE_RESP: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        axi_rd_state <= AXI_IDLE;
                    end
                end
                default: axi_rd_state <= AXI_IDLE;
            endcase
        end
    end

    // Generate start pulse for SPI logic (one clock after reg_start set)
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            start_pulse <= 1'b0;
            spi_active  <= 1'b0;
        end else begin
            if (reg_start && !spi_active) begin
                start_pulse <= 1'b1;
                spi_active  <= 1'b1;
            end else begin
                start_pulse <= 1'b0;
                if (reg_done) spi_active <= 1'b0;
            end
        end
    end

    // SPI FSM
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            tx_shift <= 8'h00;
            rx_shift <= 8'h00;
            bit_count <= 3'h0;
            sck <= 1'b0;
            cs_n <= 1'b1;
            reg_done <= 1'b0;
            reg_rx_data <= 8'h00;
            io0_oe <= 1'b0;
            io1_oe <= 1'b0;
            io0_out <= 1'b0;
            io1_out <= 1'b0;
        end else if (start_pulse && cs_n) begin
            tx_shift <= reg_tx_data;
            if (reg_mode) begin
                bit_count <= 3'h3;
            end else begin
                bit_count <= 3'h7;
            end
            cs_n <= 1'b0;
            io0_oe <= 1'b1;
            if (reg_mode) begin
                io1_oe <= 1'b1;
            end else begin
                io1_oe <= 1'b0;
            end
            reg_done <= 1'b0;
        end else if (!cs_n) begin
            sck <= ~sck;
            if (sck) begin // Rising edge
                if (reg_mode) begin
                    rx_shift <= {rx_shift[5:0], io1, io0};
                    if (bit_count == 0) begin
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end else begin
                    rx_shift <= {rx_shift[6:0], io1};
                    if (bit_count == 0) begin
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end
            end else begin // Falling edge
                if (reg_mode) begin
                    io0_out <= tx_shift[1];
                    io1_out <= tx_shift[0];
                    tx_shift <= {tx_shift[5:0], 2'b00};
                end else begin
                    io0_out <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                end
                if (bit_count == 0) begin
                    cs_n <= 1'b1;
                    reg_done <= 1'b1;
                    reg_rx_data <= rx_shift;
                    io0_oe <= 1'b0;
                    io1_oe <= 1'b0;
                end
            end
        end else begin
            sck <= 1'b0;
            reg_done <= 1'b0;
        end
    end

endmodule