//SystemVerilog
module polarity_config_reset_detector_axi4lite #(
    parameter ADDR_WIDTH = 4  // Enough for a few registers
)(
    input  wire              clk,
    input  wire              rst_n,

    // AXI4-Lite Slave Interface
    // Write address channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,
    // Write data channel
    input  wire [31:0]           s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,
    // Write response channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,
    // Read address channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,
    // Read data channel
    output reg  [31:0]           s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // Register map
    localparam REG_RESET_INPUTS_ADDR     = 4'h0;
    localparam REG_POLARITY_CONFIG_ADDR  = 4'h4;
    localparam REG_DETECTED_RESETS_ADDR  = 4'h8;
    localparam REG_VALID_OUT_ADDR        = 4'hC;

    // Internal registers for input
    reg [3:0] reset_inputs_reg;
    reg [3:0] polarity_config_reg;

    // Stage 1: Input latch and normalization calculation
    reg  [3:0] reset_inputs_stage1;
    reg  [3:0] polarity_config_stage1;
    reg        valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_inputs_stage1    <= 4'b0;
            polarity_config_stage1 <= 4'b0;
            valid_stage1           <= 1'b0;
        end else begin
            reset_inputs_stage1    <= reset_inputs_reg;
            polarity_config_stage1 <= polarity_config_reg;
            valid_stage1           <= 1'b1;
        end
    end

    // Stage 2: Normalization logic
    reg [3:0] normalized_inputs_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            normalized_inputs_stage2 <= 4'b0;
            valid_stage2             <= 1'b0;
        end else begin
            normalized_inputs_stage2[0] <= polarity_config_stage1[0] ? reset_inputs_stage1[0] : ~reset_inputs_stage1[0];
            normalized_inputs_stage2[1] <= polarity_config_stage1[1] ? reset_inputs_stage1[1] : ~reset_inputs_stage1[1];
            normalized_inputs_stage2[2] <= polarity_config_stage1[2] ? reset_inputs_stage1[2] : ~reset_inputs_stage1[2];
            normalized_inputs_stage2[3] <= polarity_config_stage1[3] ? reset_inputs_stage1[3] : ~reset_inputs_stage1[3];
            valid_stage2               <= valid_stage1;
        end
    end

    // Stage 3: Output register
    reg [3:0] detected_resets_reg;
    reg       valid_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_resets_reg <= 4'b0;
            valid_out_reg       <= 1'b0;
        end else begin
            detected_resets_reg <= normalized_inputs_stage2;
            valid_out_reg       <= valid_stage2;
        end
    end

    // AXI4-Lite Write FSM
    localparam WR_IDLE = 2'd0, WR_DATA = 2'd1, WR_RESP = 2'd2;
    reg [1:0] wr_state, wr_state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_state <= WR_IDLE;
        else
            wr_state <= wr_state_next;
    end

    always @(*) begin
        wr_state_next = wr_state;
        case (wr_state)
            WR_IDLE:  if (s_axi_awvalid && s_axi_wvalid) wr_state_next = WR_RESP;
                      else if (s_axi_awvalid) wr_state_next = WR_DATA;
            WR_DATA:  if (s_axi_wvalid) wr_state_next = WR_RESP;
            WR_RESP:  if (s_axi_bready) wr_state_next = WR_IDLE;
        endcase
    end

    // AXI4-Lite Write handshake and register write
    reg [ADDR_WIDTH-1:0] axi_awaddr_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_awaddr_latched <= {ADDR_WIDTH{1'b0}};
        else if ((wr_state == WR_IDLE) && s_axi_awvalid)
            axi_awaddr_latched <= s_axi_awaddr;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_inputs_reg    <= 4'b0;
            polarity_config_reg <= 4'b0;
        end else if ((wr_state == WR_DATA && s_axi_wvalid) || (wr_state == WR_IDLE && s_axi_awvalid && s_axi_wvalid)) begin
            case (wr_state == WR_DATA ? axi_awaddr_latched : s_axi_awaddr)
                REG_RESET_INPUTS_ADDR: begin
                    if (s_axi_wstrb[0]) reset_inputs_reg    <= s_axi_wdata[3:0];
                end
                REG_POLARITY_CONFIG_ADDR: begin
                    if (s_axi_wstrb[0]) polarity_config_reg <= s_axi_wdata[3:0];
                end
                default: ;
            endcase
        end
    end

    // AXI4-Lite write channel handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= ~s_axi_awready && s_axi_awvalid;
                    s_axi_wready  <= ~s_axi_wready && s_axi_wvalid;
                    s_axi_bvalid  <= 1'b0;
                    s_axi_bresp   <= 2'b00;
                end
                WR_DATA: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= s_axi_wvalid;
                    s_axi_bvalid  <= 1'b0;
                end
                WR_RESP: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b1;
                    s_axi_bresp   <= 2'b00;
                end
            endcase
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // AXI4-Lite Read FSM
    localparam RD_IDLE = 2'd0, RD_DATA = 2'd1;
    reg [1:0] rd_state, rd_state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_state <= RD_IDLE;
        else
            rd_state <= rd_state_next;
    end

    always @(*) begin
        rd_state_next = rd_state;
        case (rd_state)
            RD_IDLE: if (s_axi_arvalid) rd_state_next = RD_DATA;
            RD_DATA: if (s_axi_rready) rd_state_next = RD_IDLE;
        endcase
    end

    reg [ADDR_WIDTH-1:0] axi_araddr_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_araddr_latched <= {ADDR_WIDTH{1'b0}};
        else if (rd_state == RD_IDLE && s_axi_arvalid)
            axi_araddr_latched <= s_axi_araddr;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'b0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= ~s_axi_arready && s_axi_arvalid;
                    s_axi_rvalid  <= 1'b0;
                end
                RD_DATA: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    s_axi_rresp   <= 2'b00;
                    case (axi_araddr_latched)
                        REG_RESET_INPUTS_ADDR:    s_axi_rdata <= {28'b0, reset_inputs_reg};
                        REG_POLARITY_CONFIG_ADDR: s_axi_rdata <= {28'b0, polarity_config_reg};
                        REG_DETECTED_RESETS_ADDR: s_axi_rdata <= {28'b0, detected_resets_reg};
                        REG_VALID_OUT_ADDR:       s_axi_rdata <= {31'b0, valid_out_reg};
                        default:                  s_axi_rdata <= 32'b0;
                    endcase
                end
            endcase
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

endmodule