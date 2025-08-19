//SystemVerilog
module spi_master_dma_axi4lite #(
    parameter C_S_AXI_DATA_WIDTH = 16,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    input wire                      S_AXI_ACLK,
    input wire                      S_AXI_ARESETN,

    // AXI4-Lite Slave Interface
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire                          S_AXI_AWVALID,
    output reg                          S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire                          S_AXI_WVALID,
    output reg                          S_AXI_WREADY,
    output reg [1:0]                    S_AXI_BRESP,
    output reg                          S_AXI_BVALID,
    input wire                          S_AXI_BREADY,

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire                          S_AXI_ARVALID,
    output reg                          S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0]                    S_AXI_RRESP,
    output reg                          S_AXI_RVALID,
    input wire                          S_AXI_RREADY,

    // SPI interface
    output reg sclk,
    output reg cs_n,
    output wire mosi,
    input wire miso
);

// AXI4-Lite internal registers
// Address mapping
localparam ADDR_DMA_DATA_IN         = 4'h0; // [7:0] write
localparam ADDR_DMA_VALID_IN        = 4'h2; // [0] write
localparam ADDR_DMA_READY_OUT       = 4'h4; // [0] read
localparam ADDR_DMA_DATA_OUT        = 4'h6; // [7:0] read
localparam ADDR_DMA_VALID_OUT       = 4'h8; // [0] read
localparam ADDR_DMA_READY_IN        = 4'hA; // [0] write
localparam ADDR_TRANSFER_START      = 4'hC; // [0] write
localparam ADDR_TRANSFER_LENGTH     = 4'hE; // [15:0] write/read
localparam ADDR_TRANSFER_BUSY       = 4'h10;// [0] read
localparam ADDR_TRANSFER_DONE       = 4'h12;// [0] read

// Internal registers for interface emulation
reg [7:0]  reg_dma_data_in;
reg        reg_dma_valid_in;
wire       dma_ready_out_int;
wire [7:0] dma_data_out_int;
wire       dma_valid_out_int;
reg        reg_dma_ready_in;
reg        reg_transfer_start;
reg [15:0] reg_transfer_length;
wire       transfer_busy_int;
wire       transfer_done_int;

// AXI4-Lite handshake signals
reg aw_en;

// FSM states
localparam IDLE        = 3'd0;
localparam LOAD        = 3'd1;
localparam SHIFT_OUT   = 3'd2;
localparam SHIFT_IN    = 3'd3;
localparam STORE       = 3'd4;
localparam FINISH      = 3'd5;

// Pipeline stage registers
reg [2:0]  state_stage2, state_stage3, state_stage4, state_stage1_comb;
reg [7:0]  tx_shift_stage2, tx_shift_stage3, tx_shift_stage4, tx_shift_stage1_comb;
reg [7:0]  rx_shift_stage2, rx_shift_stage3, rx_shift_stage4, rx_shift_stage1_comb;
reg [2:0]  bit_count_stage2, bit_count_stage3, bit_count_stage4, bit_count_stage1_comb;
reg [15:0] byte_count_stage2, byte_count_stage3, byte_count_stage4, byte_count_stage1_comb;
reg        cs_n_stage2, cs_n_stage3, cs_n_stage4, cs_n_stage1_comb;
reg        sclk_stage2, sclk_stage3, sclk_stage4, sclk_stage1_comb;
reg        transfer_busy_stage2, transfer_busy_stage3, transfer_busy_stage4, transfer_busy_stage1_comb;
reg        transfer_done_stage2, transfer_done_stage3, transfer_done_stage4, transfer_done_stage1_comb;
reg        dma_ready_out_stage2, dma_ready_out_stage3, dma_ready_out_stage4, dma_ready_out_stage1_comb;
reg [7:0]  dma_data_out_stage2, dma_data_out_stage3, dma_data_out_stage4, dma_data_out_stage1_comb;
reg        dma_valid_out_stage2, dma_valid_out_stage3, dma_valid_out_stage4, dma_valid_out_stage1_comb;

// Valid signals for each stage
reg        valid_stage2, valid_stage3, valid_stage4, valid_stage1_comb;

// Flush logic
wire flush_pipeline;
assign flush_pipeline = !S_AXI_ARESETN;

// Forwarding for mosi
assign mosi = tx_shift_stage2[7];

// AXI4-Lite Write Address Channel
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_AWREADY <= 1'b0;
        aw_en <= 1'b1;
    end else begin
        if (!S_AXI_AWREADY && S_AXI_AWVALID && aw_en) begin
            S_AXI_AWREADY <= 1'b1;
            aw_en <= 1'b0;
        end else if (S_AXI_BREADY && S_AXI_BVALID) begin
            aw_en <= 1'b1;
            S_AXI_AWREADY <= 1'b0;
        end else begin
            S_AXI_AWREADY <= 1'b0;
        end
    end
end

// AXI4-Lite Write Data Channel
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_WREADY <= 1'b0;
    end else begin
        if (!S_AXI_WREADY && S_AXI_WVALID) begin
            S_AXI_WREADY <= 1'b1;
        end else begin
            S_AXI_WREADY <= 1'b0;
        end
    end
end

// AXI4-Lite Write Response Channel
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_BVALID <= 1'b0;
        S_AXI_BRESP  <= 2'b00;
    end else begin
        if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
            S_AXI_BVALID <= 1'b1;
            S_AXI_BRESP  <= 2'b00;
        end else if (S_AXI_BREADY && S_AXI_BVALID) begin
            S_AXI_BVALID <= 1'b0;
        end
    end
end

// AXI4-Lite Write Register Decode
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        reg_dma_data_in     <= 8'd0;
        reg_dma_valid_in    <= 1'b0;
        reg_dma_ready_in    <= 1'b0;
        reg_transfer_start  <= 1'b0;
        reg_transfer_length <= 16'd0;
    end else begin
        reg_dma_valid_in    <= 1'b0;
        reg_transfer_start  <= 1'b0;

        if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
            case (S_AXI_AWADDR[3:0])
                ADDR_DMA_DATA_IN: begin
                    reg_dma_data_in <= S_AXI_WDATA[7:0];
                end
                ADDR_DMA_VALID_IN: begin
                    reg_dma_valid_in <= S_AXI_WDATA[0];
                end
                ADDR_DMA_READY_IN: begin
                    reg_dma_ready_in <= S_AXI_WDATA[0];
                end
                ADDR_TRANSFER_START: begin
                    reg_transfer_start <= S_AXI_WDATA[0];
                end
                ADDR_TRANSFER_LENGTH: begin
                    reg_transfer_length <= S_AXI_WDATA[15:0];
                end
                default: ;
            endcase
        end
    end
end

// AXI4-Lite Read Address Channel
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_ARREADY <= 1'b0;
    end else begin
        if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
            S_AXI_ARREADY <= 1'b1;
        end else begin
            S_AXI_ARREADY <= 1'b0;
        end
    end
end

// AXI4-Lite Read Data Channel
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_RVALID <= 1'b0;
        S_AXI_RRESP  <= 2'b00;
        S_AXI_RDATA  <= {C_S_AXI_DATA_WIDTH{1'b0}};
    end else begin
        if (S_AXI_ARREADY && S_AXI_ARVALID) begin
            S_AXI_RVALID <= 1'b1;
            S_AXI_RRESP  <= 2'b00;
            case (S_AXI_ARADDR[3:0])
                ADDR_DMA_READY_OUT:   S_AXI_RDATA <= {{(C_S_AXI_DATA_WIDTH-1){1'b0}}, dma_ready_out_int};
                ADDR_DMA_DATA_OUT:    S_AXI_RDATA <= {{(C_S_AXI_DATA_WIDTH-8){1'b0}}, dma_data_out_int};
                ADDR_DMA_VALID_OUT:   S_AXI_RDATA <= {{(C_S_AXI_DATA_WIDTH-1){1'b0}}, dma_valid_out_int};
                ADDR_TRANSFER_BUSY:   S_AXI_RDATA <= {{(C_S_AXI_DATA_WIDTH-1){1'b0}}, transfer_busy_int};
                ADDR_TRANSFER_DONE:   S_AXI_RDATA <= {{(C_S_AXI_DATA_WIDTH-1){1'b0}}, transfer_done_int};
                ADDR_TRANSFER_LENGTH: S_AXI_RDATA <= reg_transfer_length;
                default:              S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
            endcase
        end else if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
        end
    end
end

// Stage 1: FSM and input latching (retimed to be combinational)
always @* begin
    // Default: hold previous values
    state_stage1_comb            = state_stage2;
    tx_shift_stage1_comb         = tx_shift_stage2;
    rx_shift_stage1_comb         = rx_shift_stage2;
    bit_count_stage1_comb        = bit_count_stage2;
    byte_count_stage1_comb       = byte_count_stage2;
    cs_n_stage1_comb             = cs_n_stage2;
    sclk_stage1_comb             = sclk_stage2;
    transfer_busy_stage1_comb    = transfer_busy_stage2;
    transfer_done_stage1_comb    = transfer_done_stage2;
    dma_ready_out_stage1_comb    = dma_ready_out_stage2;
    dma_data_out_stage1_comb     = dma_data_out_stage2;
    dma_valid_out_stage1_comb    = dma_valid_out_stage2;
    valid_stage1_comb            = valid_stage2;

    case (state_stage2)
        IDLE: begin
            transfer_done_stage1_comb = 1'b0;
            if (reg_transfer_start) begin
                transfer_busy_stage1_comb = 1'b1;
                byte_count_stage1_comb = reg_transfer_length;
                cs_n_stage1_comb = 1'b0;
                state_stage1_comb = LOAD;
                dma_ready_out_stage1_comb = 1'b1;
            end else begin
                cs_n_stage1_comb = 1'b1;
                transfer_busy_stage1_comb = 1'b0;
                dma_ready_out_stage1_comb = 1'b0;
            end
        end
        LOAD: begin
            if (reg_dma_valid_in && dma_ready_out_stage2) begin
                tx_shift_stage1_comb = reg_dma_data_in;
                bit_count_stage1_comb = 3'd7;
                dma_ready_out_stage1_comb = 1'b0;
                state_stage1_comb = SHIFT_OUT;
            end
        end
        SHIFT_OUT: begin
            sclk_stage1_comb = ~sclk_stage2;
            if (bit_count_stage2 != 3'd0) begin
                if (sclk_stage2 == 1'b0) begin
                    tx_shift_stage1_comb = {tx_shift_stage2[6:0], 1'b0};
                    bit_count_stage1_comb = bit_count_stage2 - 1'b1;
                end
            end else begin
                state_stage1_comb = SHIFT_IN;
                sclk_stage1_comb = 1'b0;
            end
        end
        SHIFT_IN: begin
            rx_shift_stage1_comb = {rx_shift_stage2[6:0], miso};
            if (bit_count_stage2 == 3'd0) begin
                state_stage1_comb = STORE;
            end else begin
                bit_count_stage1_comb = bit_count_stage2 - 1'b1;
            end
        end
        STORE: begin
            dma_data_out_stage1_comb = rx_shift_stage2;
            dma_valid_out_stage1_comb = 1'b1;
            if (reg_dma_ready_in) begin
                byte_count_stage1_comb = byte_count_stage2 - 1'b1;
                if (byte_count_stage2 == 16'd1) begin
                    state_stage1_comb = FINISH;
                end else begin
                    state_stage1_comb = LOAD;
                    dma_ready_out_stage1_comb = 1'b1;
                end
                dma_valid_out_stage1_comb = 1'b0;
            end
        end
        FINISH: begin
            cs_n_stage1_comb = 1'b1;
            transfer_busy_stage1_comb = 1'b0;
            transfer_done_stage1_comb = 1'b1;
            state_stage1_comb = IDLE;
        end
    endcase

    if (flush_pipeline) begin
        state_stage1_comb            = IDLE;
        tx_shift_stage1_comb         = 8'h00;
        rx_shift_stage1_comb         = 8'h00;
        bit_count_stage1_comb        = 3'd0;
        byte_count_stage1_comb       = 16'd0;
        cs_n_stage1_comb             = 1'b1;
        sclk_stage1_comb             = 1'b0;
        transfer_busy_stage1_comb    = 1'b0;
        transfer_done_stage1_comb    = 1'b0;
        dma_ready_out_stage1_comb    = 1'b0;
        dma_data_out_stage1_comb     = 8'd0;
        dma_valid_out_stage1_comb    = 1'b0;
        valid_stage1_comb            = 1'b0;
    end
end

// Stage 2: Pipeline register (now the first register after input and combinational logic)
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN || flush_pipeline) begin
        state_stage2            <= IDLE;
        tx_shift_stage2         <= 8'h00;
        rx_shift_stage2         <= 8'h00;
        bit_count_stage2        <= 3'd0;
        byte_count_stage2       <= 16'd0;
        cs_n_stage2             <= 1'b1;
        sclk_stage2             <= 1'b0;
        transfer_busy_stage2    <= 1'b0;
        transfer_done_stage2    <= 1'b0;
        dma_ready_out_stage2    <= 1'b0;
        dma_data_out_stage2     <= 8'd0;
        dma_valid_out_stage2    <= 1'b0;
        valid_stage2            <= 1'b0;
    end else begin
        state_stage2            <= state_stage1_comb;
        tx_shift_stage2         <= tx_shift_stage1_comb;
        rx_shift_stage2         <= rx_shift_stage1_comb;
        bit_count_stage2        <= bit_count_stage1_comb;
        byte_count_stage2       <= byte_count_stage1_comb;
        cs_n_stage2             <= cs_n_stage1_comb;
        sclk_stage2             <= sclk_stage1_comb;
        transfer_busy_stage2    <= transfer_busy_stage1_comb;
        transfer_done_stage2    <= transfer_done_stage1_comb;
        dma_ready_out_stage2    <= dma_ready_out_stage1_comb;
        dma_data_out_stage2     <= dma_data_out_stage1_comb;
        dma_valid_out_stage2    <= dma_valid_out_stage1_comb;
        valid_stage2            <= valid_stage1_comb;
    end
end

// Stage 3: Pipeline register
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN || flush_pipeline) begin
        state_stage3            <= IDLE;
        tx_shift_stage3         <= 8'h00;
        rx_shift_stage3         <= 8'h00;
        bit_count_stage3        <= 3'd0;
        byte_count_stage3       <= 16'd0;
        cs_n_stage3             <= 1'b1;
        sclk_stage3             <= 1'b0;
        transfer_busy_stage3    <= 1'b0;
        transfer_done_stage3    <= 1'b0;
        dma_ready_out_stage3    <= 1'b0;
        dma_data_out_stage3     <= 8'd0;
        dma_valid_out_stage3    <= 1'b0;
        valid_stage3            <= 1'b0;
    end else begin
        state_stage3            <= state_stage2;
        tx_shift_stage3         <= tx_shift_stage2;
        rx_shift_stage3         <= rx_shift_stage2;
        bit_count_stage3        <= bit_count_stage2;
        byte_count_stage3       <= byte_count_stage2;
        cs_n_stage3             <= cs_n_stage2;
        sclk_stage3             <= sclk_stage2;
        transfer_busy_stage3    <= transfer_busy_stage2;
        transfer_done_stage3    <= transfer_done_stage2;
        dma_ready_out_stage3    <= dma_ready_out_stage2;
        dma_data_out_stage3     <= dma_data_out_stage2;
        dma_valid_out_stage3    <= dma_valid_out_stage2;
        valid_stage3            <= valid_stage2;
    end
end

// Stage 4: Pipeline register (output stage)
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN || flush_pipeline) begin
        state_stage4            <= IDLE;
        tx_shift_stage4         <= 8'h00;
        rx_shift_stage4         <= 8'h00;
        bit_count_stage4        <= 3'd0;
        byte_count_stage4       <= 16'd0;
        cs_n_stage4             <= 1'b1;
        sclk_stage4             <= 1'b0;
        transfer_busy_stage4    <= 1'b0;
        transfer_done_stage4    <= 1'b0;
        dma_ready_out_stage4    <= 1'b0;
        dma_data_out_stage4     <= 8'd0;
        dma_valid_out_stage4    <= 1'b0;
        valid_stage4            <= 1'b0;
    end else begin
        state_stage4            <= state_stage3;
        tx_shift_stage4         <= tx_shift_stage3;
        rx_shift_stage4         <= rx_shift_stage3;
        bit_count_stage4        <= bit_count_stage3;
        byte_count_stage4       <= byte_count_stage3;
        cs_n_stage4             <= cs_n_stage3;
        sclk_stage4             <= sclk_stage3;
        transfer_busy_stage4    <= transfer_busy_stage3;
        transfer_done_stage4    <= transfer_done_stage3;
        dma_ready_out_stage4    <= dma_ready_out_stage3;
        dma_data_out_stage4     <= dma_data_out_stage3;
        dma_valid_out_stage4    <= dma_valid_out_stage3;
        valid_stage4            <= valid_stage3;
    end
end

// Output assignment from last pipeline stage
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        cs_n            <= 1'b1;
        sclk            <= 1'b0;
    end else begin
        cs_n            <= cs_n_stage4;
        sclk            <= sclk_stage4;
    end
end

// Output assignments to AXI4-Lite mapped registers
assign dma_ready_out_int    = dma_ready_out_stage4;
assign dma_data_out_int     = dma_data_out_stage4;
assign dma_valid_out_int    = dma_valid_out_stage4;
assign transfer_busy_int    = transfer_busy_stage4;
assign transfer_done_int    = transfer_done_stage4;

endmodule