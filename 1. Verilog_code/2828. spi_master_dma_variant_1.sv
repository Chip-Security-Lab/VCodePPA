//SystemVerilog
module spi_master_dma_axi4lite #(
    parameter ADDR_WIDTH = 4,      // 16 bytes addressable (enough for 8x16b regs)
    parameter DATA_WIDTH = 16      // AXI4-Lite data width is 16 bits per requirement
)(
    input                     clk,
    input                     rst_n,

    // AXI4-Lite Slave Write Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                       s_axi_awvalid,
    output reg                  s_axi_awready,

    // AXI4-Lite Slave Write Data Channel
    input      [DATA_WIDTH-1:0] s_axi_wdata,
    input   [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                        s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4-Lite Slave Write Response Channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input                        s_axi_bready,

    // AXI4-Lite Slave Read Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_araddr,
    input                       s_axi_arvalid,
    output reg                  s_axi_arready,

    // AXI4-Lite Slave Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]           s_axi_rresp,
    output reg                  s_axi_rvalid,
    input                       s_axi_rready,

    // SPI interface
    output reg                  sclk,
    output reg                  cs_n,
    output                      mosi,
    input                       miso
);

// Address Map
localparam ADDR_TRANSFER_START    = 4'h0; // W
localparam ADDR_TRANSFER_LENGTH   = 4'h2; // W
localparam ADDR_TRANSFER_BUSY     = 4'h4; // R
localparam ADDR_TRANSFER_DONE     = 4'h6; // R
localparam ADDR_DMA_DATA_IN       = 4'h8; // W
localparam ADDR_DMA_DATA_OUT      = 4'hA; // R
localparam ADDR_DMA_STATUS        = 4'hC; // R

// Internal registers mapped to AXI4-Lite
reg         transfer_start_reg;
reg [15:0]  transfer_length_reg;
reg         transfer_busy_reg;
reg         transfer_done_reg;

// DMA FIFO for input/output (8 bit each, but mapped to 16b AXI)
reg  [7:0]  dma_data_in_reg;
reg         dma_data_in_valid;
reg         dma_data_in_ready;
reg  [7:0]  dma_data_out_reg;
reg         dma_data_out_valid;
reg         dma_data_out_ready;

// DMA status register bits: [1]=data_out_valid, [0]=data_in_ready
wire [15:0] dma_status_reg = {14'd0, dma_data_out_valid, dma_data_in_ready};

// AXI4-Lite handshake state
reg         aw_hs, w_hs, ar_hs;

// AXI4-Lite Write FSM
reg  [ADDR_WIDTH-1:0] awaddr_reg;
reg                   awaddr_valid;

// AXI4-Lite Read FSM
reg  [ADDR_WIDTH-1:0] araddr_reg;
reg                   araddr_valid;

// SPI Master DMA core pipeline logic (as in original, with DMA mapped)
localparam IDLE_STAGE        = 3'd0;
localparam LOAD_STAGE        = 3'd1;
localparam SHIFT_OUT_STAGE   = 3'd2;
localparam SHIFT_IN_STAGE    = 3'd3;
localparam STORE_STAGE       = 3'd4;
localparam FINISH_STAGE      = 3'd5;
localparam PIPELINE_STAGES   = 5;

// Pipeline registers
reg [2:0]  state_stage1, state_stage2, state_stage3, state_stage4, state_stage5, state_stage6;
reg        valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5, valid_stage6;
reg        flush_stage1, flush_stage2, flush_stage3, flush_stage4, flush_stage5, flush_stage6;
reg [7:0]  tx_shift_stage1, tx_shift_stage2, tx_shift_stage3, tx_shift_stage4, tx_shift_stage5, tx_shift_stage6;
reg [7:0]  rx_shift_stage1, rx_shift_stage2, rx_shift_stage3, rx_shift_stage4, rx_shift_stage5, rx_shift_stage6;
reg [2:0]  bit_count_stage1, bit_count_stage2, bit_count_stage3, bit_count_stage4, bit_count_stage5, bit_count_stage6;
reg [15:0] byte_count_stage1, byte_count_stage2, byte_count_stage3, byte_count_stage4, byte_count_stage5, byte_count_stage6;
reg        transfer_busy_stage1, transfer_busy_stage2, transfer_busy_stage3, transfer_busy_stage4, transfer_busy_stage5, transfer_busy_stage6;
reg        transfer_done_stage1, transfer_done_stage2, transfer_done_stage3, transfer_done_stage4, transfer_done_stage5, transfer_done_stage6;
reg        cs_n_stage1, cs_n_stage2, cs_n_stage3, cs_n_stage4, cs_n_stage5, cs_n_stage6;
reg        sclk_stage1, sclk_stage2, sclk_stage3, sclk_stage4, sclk_stage5, sclk_stage6;
reg        dma_ready_out_stage1, dma_ready_out_stage2, dma_ready_out_stage3, dma_ready_out_stage4, dma_ready_out_stage5, dma_ready_out_stage6;
reg        dma_valid_out_stage1, dma_valid_out_stage2, dma_valid_out_stage3, dma_valid_out_stage4, dma_valid_out_stage5, dma_valid_out_stage6;
reg [7:0]  dma_data_out_stage1, dma_data_out_stage2, dma_data_out_stage3, dma_data_out_stage4, dma_data_out_stage5, dma_data_out_stage6;

// Output assign
assign mosi = tx_shift_stage6[7];

// Flush logic
wire flush = (!rst_n);

// AXI4-Lite Write Address Channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_awready  <= 1'b0;
        awaddr_reg     <= {ADDR_WIDTH{1'b0}};
        awaddr_valid   <= 1'b0;
    end else begin
        if (!s_axi_awready && s_axi_awvalid) begin
            s_axi_awready  <= 1'b1;
            awaddr_reg     <= s_axi_awaddr;
            awaddr_valid   <= 1'b1;
        end else if (w_hs) begin
            s_axi_awready  <= 1'b0;
            awaddr_valid   <= 1'b0;
        end else begin
            if (!s_axi_awvalid) s_axi_awready <= 1'b0;
        end
    end
end

// AXI4-Lite Write Data Channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_wready   <= 1'b0;
    end else begin
        if (!s_axi_wready && s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
        end else if (w_hs) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (!s_axi_wvalid) s_axi_wready <= 1'b0;
        end
    end
end

assign w_hs  = s_axi_wvalid && s_axi_wready;
assign aw_hs = s_axi_awvalid && s_axi_awready;

// AXI4-Lite Write Response Channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_bvalid <= 1'b0;
        s_axi_bresp  <= 2'b00;
    end else begin
        if (w_hs) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

// AXI4-Lite Read Address Channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_arready <= 1'b0;
        araddr_reg    <= {ADDR_WIDTH{1'b0}};
        araddr_valid  <= 1'b0;
    end else begin
        if (!s_axi_arready && s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
            araddr_reg    <= s_axi_araddr;
            araddr_valid  <= 1'b1;
        end else if (ar_hs) begin
            s_axi_arready <= 1'b0;
            araddr_valid  <= 1'b0;
        end else begin
            if (!s_axi_arvalid) s_axi_arready <= 1'b0;
        end
    end
end

assign ar_hs = s_axi_arvalid && s_axi_arready;

// AXI4-Lite Read Data Channel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_rvalid <= 1'b0;
        s_axi_rresp  <= 2'b00;
        s_axi_rdata  <= {DATA_WIDTH{1'b0}};
    end else begin
        if (ar_hs) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= 2'b00;
            case (araddr_reg)
                ADDR_TRANSFER_START:   s_axi_rdata <= {15'd0, transfer_start_reg};
                ADDR_TRANSFER_LENGTH:  s_axi_rdata <= transfer_length_reg;
                ADDR_TRANSFER_BUSY:    s_axi_rdata <= {15'd0, transfer_busy_reg};
                ADDR_TRANSFER_DONE:    s_axi_rdata <= {15'd0, transfer_done_reg};
                ADDR_DMA_DATA_IN:      s_axi_rdata <= {8'd0, dma_data_in_reg};
                ADDR_DMA_DATA_OUT:     s_axi_rdata <= {8'd0, dma_data_out_reg};
                ADDR_DMA_STATUS:       s_axi_rdata <= dma_status_reg;
                default:               s_axi_rdata <= {DATA_WIDTH{1'b0}};
            endcase
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

// AXI4-Lite Write Register Mapping
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        transfer_start_reg   <= 1'b0;
        transfer_length_reg  <= 16'd0;
        dma_data_in_reg      <= 8'd0;
        dma_data_in_valid    <= 1'b0;
    end else begin
        dma_data_in_valid    <= 1'b0;
        if (w_hs) begin
            case (awaddr_reg)
                ADDR_TRANSFER_START: begin
                    if (s_axi_wstrb[0]) transfer_start_reg <= s_axi_wdata[0];
                end
                ADDR_TRANSFER_LENGTH: begin
                    if (s_axi_wstrb[1]) transfer_length_reg[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) transfer_length_reg[7:0]  <= s_axi_wdata[7:0];
                end
                ADDR_DMA_DATA_IN: begin
                    if (s_axi_wstrb[0]) begin
                        dma_data_in_reg   <= s_axi_wdata[7:0];
                        dma_data_in_valid <= 1'b1;
                    end
                end
                default: ;
            endcase
        end
    end
end

// Clear transfer_start_reg after use
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        transfer_start_reg <= 1'b0;
    end else if (transfer_start_reg) begin
        transfer_start_reg <= 1'b0;
    end
end

// DMA input ready logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_data_in_ready <= 1'b1;
    end else begin
        if (dma_data_in_valid && dma_data_in_ready) begin
            dma_data_in_ready <= 1'b0;
        end else if (state_stage6 == LOAD_STAGE && dma_ready_out_stage6) begin
            dma_data_in_ready <= 1'b1;
        end
    end
end

// DMA output handshake
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_data_out_ready <= 1'b0;
    end else begin
        if (dma_data_out_valid) begin
            dma_data_out_ready <= 1'b1;
        end else if (!dma_data_out_valid) begin
            dma_data_out_ready <= 1'b0;
        end
    end
end

// DMA output valid clear after read via AXI
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_data_out_valid <= 1'b0;
    end else if (ar_hs && araddr_reg == ADDR_DMA_DATA_OUT) begin
        dma_data_out_valid <= 1'b0;
    end else if (dma_valid_out_stage6) begin
        dma_data_out_valid <= 1'b1;
    end
end

// DMA output data register update
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_data_out_reg <= 8'd0;
    end else if (dma_valid_out_stage6) begin
        dma_data_out_reg <= dma_data_out_stage6;
    end
end

// SPI Master DMA pipeline logic (same as original, but using DMA regs)
// Pipeline stage 1: State and input capture
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1           <= IDLE_STAGE;
        tx_shift_stage1        <= 8'h00;
        rx_shift_stage1        <= 8'h00;
        bit_count_stage1       <= 3'd0;
        byte_count_stage1      <= 16'd0;
        cs_n_stage1            <= 1'b1;
        sclk_stage1            <= 1'b0;
        transfer_busy_stage1   <= 1'b0;
        transfer_done_stage1   <= 1'b0;
        dma_ready_out_stage1   <= 1'b0;
        dma_valid_out_stage1   <= 1'b0;
        dma_data_out_stage1    <= 8'h00;
        valid_stage1           <= 1'b0;
        flush_stage1           <= 1'b1;
    end else begin
        flush_stage1           <= flush;
        valid_stage1           <= 1'b1;
        case (state_stage1)
            IDLE_STAGE: begin
                if (transfer_start_reg) begin
                    state_stage1         <= LOAD_STAGE;
                    transfer_busy_stage1 <= 1'b1;
                    transfer_done_stage1 <= 1'b0;
                    byte_count_stage1    <= transfer_length_reg;
                    cs_n_stage1          <= 1'b0;
                    dma_ready_out_stage1 <= 1'b1;
                end else begin
                    state_stage1         <= IDLE_STAGE;
                    transfer_busy_stage1 <= 1'b0;
                    transfer_done_stage1 <= 1'b0;
                    cs_n_stage1          <= 1'b1;
                    dma_ready_out_stage1 <= 1'b0;
                end
                tx_shift_stage1          <= 8'h00;
                rx_shift_stage1          <= 8'h00;
                bit_count_stage1         <= 3'd0;
                sclk_stage1              <= 1'b0;
                dma_valid_out_stage1     <= 1'b0;
                dma_data_out_stage1      <= 8'h00;
            end
            LOAD_STAGE: begin
                if (dma_data_in_valid && dma_data_in_ready) begin
                    tx_shift_stage1      <= dma_data_in_reg;
                    bit_count_stage1     <= 3'd7;
                    dma_ready_out_stage1 <= 1'b0;
                    state_stage1         <= SHIFT_OUT_STAGE;
                end else begin
                    state_stage1         <= LOAD_STAGE;
                end
                rx_shift_stage1          <= rx_shift_stage1;
                byte_count_stage1        <= byte_count_stage1;
                cs_n_stage1              <= cs_n_stage1;
                sclk_stage1              <= sclk_stage1;
                dma_valid_out_stage1     <= 1'b0;
                dma_data_out_stage1      <= dma_data_out_stage1;
            end
            SHIFT_OUT_STAGE: begin
                state_stage1             <= SHIFT_OUT_STAGE;
                tx_shift_stage1          <= tx_shift_stage1;
                rx_shift_stage1          <= rx_shift_stage1;
                bit_count_stage1         <= bit_count_stage1;
                byte_count_stage1        <= byte_count_stage1;
                cs_n_stage1              <= cs_n_stage1;
                sclk_stage1              <= sclk_stage1;
                dma_valid_out_stage1     <= 1'b0;
                dma_data_out_stage1      <= dma_data_out_stage1;
            end
            FINISH_STAGE: begin
                cs_n_stage1            <= 1'b1;
                transfer_busy_stage1   <= 1'b0;
                transfer_done_stage1   <= 1'b1;
                state_stage1           <= IDLE_STAGE;
                tx_shift_stage1        <= 8'h00;
                rx_shift_stage1        <= 8'h00;
                bit_count_stage1       <= 3'd0;
                byte_count_stage1      <= 16'd0;
                sclk_stage1            <= 1'b0;
                dma_ready_out_stage1   <= 1'b0;
                dma_valid_out_stage1   <= 1'b0;
                dma_data_out_stage1    <= 8'h00;
            end
            default: begin
                state_stage1           <= IDLE_STAGE;
                tx_shift_stage1        <= 8'h00;
                rx_shift_stage1        <= 8'h00;
                bit_count_stage1       <= 3'd0;
                byte_count_stage1      <= 16'd0;
                cs_n_stage1            <= 1'b1;
                sclk_stage1            <= 1'b0;
                transfer_busy_stage1   <= 1'b0;
                transfer_done_stage1   <= 1'b0;
                dma_ready_out_stage1   <= 1'b0;
                dma_valid_out_stage1   <= 1'b0;
                dma_data_out_stage1    <= 8'h00;
            end
        endcase
    end
end

// Pipeline stage 2: Prepare shifting out
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2           <= IDLE_STAGE;
        tx_shift_stage2        <= 8'h00;
        rx_shift_stage2        <= 8'h00;
        bit_count_stage2       <= 3'd0;
        byte_count_stage2      <= 16'd0;
        cs_n_stage2            <= 1'b1;
        sclk_stage2            <= 1'b0;
        transfer_busy_stage2   <= 1'b0;
        transfer_done_stage2   <= 1'b0;
        dma_ready_out_stage2   <= 1'b0;
        dma_valid_out_stage2   <= 1'b0;
        dma_data_out_stage2    <= 8'h00;
        valid_stage2           <= 1'b0;
        flush_stage2           <= 1'b1;
    end else begin
        flush_stage2           <= flush_stage1;
        valid_stage2           <= valid_stage1 & ~flush_stage1;
        state_stage2           <= state_stage1;
        tx_shift_stage2        <= tx_shift_stage1;
        rx_shift_stage2        <= rx_shift_stage1;
        bit_count_stage2       <= bit_count_stage1;
        byte_count_stage2      <= byte_count_stage1;
        cs_n_stage2            <= cs_n_stage1;
        sclk_stage2            <= sclk_stage1;
        transfer_busy_stage2   <= transfer_busy_stage1;
        transfer_done_stage2   <= transfer_done_stage1;
        dma_ready_out_stage2   <= dma_ready_out_stage1;
        dma_valid_out_stage2   <= dma_valid_out_stage1;
        dma_data_out_stage2    <= dma_data_out_stage1;
    end
end

// Pipeline stage 3: Shift out one bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage3           <= IDLE_STAGE;
        tx_shift_stage3        <= 8'h00;
        rx_shift_stage3        <= 8'h00;
        bit_count_stage3       <= 3'd0;
        byte_count_stage3      <= 16'd0;
        cs_n_stage3            <= 1'b1;
        sclk_stage3            <= 1'b0;
        transfer_busy_stage3   <= 1'b0;
        transfer_done_stage3   <= 1'b0;
        dma_ready_out_stage3   <= 1'b0;
        dma_valid_out_stage3   <= 1'b0;
        dma_data_out_stage3    <= 8'h00;
        valid_stage3           <= 1'b0;
        flush_stage3           <= 1'b1;
    end else begin
        flush_stage3           <= flush_stage2;
        valid_stage3           <= valid_stage2 & ~flush_stage2;
        state_stage3           <= state_stage2;
        tx_shift_stage3        <= tx_shift_stage2;
        rx_shift_stage3        <= rx_shift_stage2;
        bit_count_stage3       <= bit_count_stage2;
        byte_count_stage3      <= byte_count_stage2;
        cs_n_stage3            <= cs_n_stage2;
        sclk_stage3            <= sclk_stage2;
        transfer_busy_stage3   <= transfer_busy_stage2;
        transfer_done_stage3   <= transfer_done_stage2;
        dma_ready_out_stage3   <= dma_ready_out_stage2;
        dma_valid_out_stage3   <= dma_valid_out_stage2;
        dma_data_out_stage3    <= dma_data_out_stage2;
        if (state_stage2 == SHIFT_OUT_STAGE && valid_stage2) begin
            tx_shift_stage3    <= {tx_shift_stage2[6:0], 1'b0};
            sclk_stage3        <= ~sclk_stage2;
        end
    end
end

// Pipeline stage 4: Sample MISO and count bits
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage4           <= IDLE_STAGE;
        tx_shift_stage4        <= 8'h00;
        rx_shift_stage4        <= 8'h00;
        bit_count_stage4       <= 3'd0;
        byte_count_stage4      <= 16'd0;
        cs_n_stage4            <= 1'b1;
        sclk_stage4            <= 1'b0;
        transfer_busy_stage4   <= 1'b0;
        transfer_done_stage4   <= 1'b0;
        dma_ready_out_stage4   <= 1'b0;
        dma_valid_out_stage4   <= 1'b0;
        dma_data_out_stage4    <= 8'h00;
        valid_stage4           <= 1'b0;
        flush_stage4           <= 1'b1;
    end else begin
        flush_stage4           <= flush_stage3;
        valid_stage4           <= valid_stage3 & ~flush_stage3;
        state_stage4           <= state_stage3;
        tx_shift_stage4        <= tx_shift_stage3;
        rx_shift_stage4        <= rx_shift_stage3;
        bit_count_stage4       <= bit_count_stage3;
        byte_count_stage4      <= byte_count_stage3;
        cs_n_stage4            <= cs_n_stage3;
        sclk_stage4            <= sclk_stage3;
        transfer_busy_stage4   <= transfer_busy_stage3;
        transfer_done_stage4   <= transfer_done_stage3;
        dma_ready_out_stage4   <= dma_ready_out_stage3;
        dma_valid_out_stage4   <= dma_valid_out_stage3;
        dma_data_out_stage4    <= dma_data_out_stage3;
        if (state_stage3 == SHIFT_OUT_STAGE && valid_stage3) begin
            rx_shift_stage4    <= {rx_shift_stage3[6:0], miso};
            if (bit_count_stage3 == 3'd0) begin
                state_stage4         <= SHIFT_IN_STAGE;
                bit_count_stage4     <= 3'd7;
            end else begin
                state_stage4         <= SHIFT_OUT_STAGE;
                bit_count_stage4     <= bit_count_stage3 - 1'b1;
            end
        end
    end
end

// Pipeline stage 5: Byte store and control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage5           <= IDLE_STAGE;
        tx_shift_stage5        <= 8'h00;
        rx_shift_stage5        <= 8'h00;
        bit_count_stage5       <= 3'd0;
        byte_count_stage5      <= 16'd0;
        cs_n_stage5            <= 1'b1;
        sclk_stage5            <= 1'b0;
        transfer_busy_stage5   <= 1'b0;
        transfer_done_stage5   <= 1'b0;
        dma_ready_out_stage5   <= 1'b0;
        dma_valid_out_stage5   <= 1'b0;
        dma_data_out_stage5    <= 8'h00;
        valid_stage5           <= 1'b0;
        flush_stage5           <= 1'b1;
    end else begin
        flush_stage5           <= flush_stage4;
        valid_stage5           <= valid_stage4 & ~flush_stage4;
        state_stage5           <= state_stage4;
        tx_shift_stage5        <= tx_shift_stage4;
        rx_shift_stage5        <= rx_shift_stage4;
        bit_count_stage5       <= bit_count_stage4;
        byte_count_stage5      <= byte_count_stage4;
        cs_n_stage5            <= cs_n_stage4;
        sclk_stage5            <= sclk_stage4;
        transfer_busy_stage5   <= transfer_busy_stage4;
        transfer_done_stage5   <= transfer_done_stage4;
        dma_ready_out_stage5   <= dma_ready_out_stage4;
        dma_valid_out_stage5   <= dma_valid_out_stage4;
        dma_data_out_stage5    <= dma_data_out_stage4;
        if (state_stage4 == SHIFT_IN_STAGE && valid_stage4) begin
            dma_data_out_stage5    <= rx_shift_stage4;
            dma_valid_out_stage5   <= 1'b1;
            if (byte_count_stage4 == 16'd1) begin
                state_stage5         <= FINISH_STAGE;
                transfer_done_stage5 <= 1'b1;
                transfer_busy_stage5 <= 1'b0;
                cs_n_stage5          <= 1'b1;
                dma_ready_out_stage5 <= 1'b0;
            end else begin
                byte_count_stage5    <= byte_count_stage4 - 1'b1;
                state_stage5         <= LOAD_STAGE;
                dma_ready_out_stage5 <= 1'b1;
                cs_n_stage5          <= 1'b0;
            end
        end
    end
end

// Pipeline stage 6: Output register stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage6           <= IDLE_STAGE;
        tx_shift_stage6        <= 8'h00;
        rx_shift_stage6        <= 8'h00;
        bit_count_stage6       <= 3'd0;
        byte_count_stage6      <= 16'd0;
        cs_n_stage6            <= 1'b1;
        sclk_stage6            <= 1'b0;
        transfer_busy_stage6   <= 1'b0;
        transfer_done_stage6   <= 1'b0;
        dma_ready_out_stage6   <= 1'b0;
        dma_valid_out_stage6   <= 1'b0;
        dma_data_out_stage6    <= 8'h00;
        valid_stage6           <= 1'b0;
        flush_stage6           <= 1'b1;
    end else begin
        flush_stage6           <= flush_stage5;
        valid_stage6           <= valid_stage5 & ~flush_stage5;
        state_stage6           <= state_stage5;
        tx_shift_stage6        <= tx_shift_stage5;
        rx_shift_stage6        <= rx_shift_stage5;
        bit_count_stage6       <= bit_count_stage5;
        byte_count_stage6      <= byte_count_stage5;
        cs_n_stage6            <= cs_n_stage5;
        sclk_stage6            <= sclk_stage5;
        transfer_busy_stage6   <= transfer_busy_stage5;
        transfer_done_stage6   <= transfer_done_stage5;
        dma_ready_out_stage6   <= dma_ready_out_stage5;
        dma_valid_out_stage6   <= dma_valid_out_stage5;
        dma_data_out_stage6    <= dma_data_out_stage5;
    end
end

// Output registers and valid/flush control (final output)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        transfer_busy_reg      <= 1'b0;
        transfer_done_reg      <= 1'b0;
        cs_n                   <= 1'b1;
        sclk                   <= 1'b0;
    end else begin
        transfer_busy_reg      <= transfer_busy_stage6;
        transfer_done_reg      <= transfer_done_stage6;
        cs_n                   <= cs_n_stage6;
        sclk                   <= sclk_stage6;
    end
end

endmodule