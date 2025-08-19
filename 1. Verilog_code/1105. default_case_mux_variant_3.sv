//SystemVerilog
module axi4lite_mux #(
    parameter ADDR_WIDTH = 4,   // Enough for 5 channels and selected output
    parameter DATA_WIDTH = 16
)(
    // AXI4-Lite Slave Interface
    input  wire                   s_axi_aclk,
    input  wire                   s_axi_aresetn,
    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,
    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,
    // Write Response Channel
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,
    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,
    // Read Data Channel
    output reg [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]              s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    // Address map
    localparam ADDR_CH0 = 4'h0;
    localparam ADDR_CH1 = 4'h2;
    localparam ADDR_CH2 = 4'h4;
    localparam ADDR_CH3 = 4'h6;
    localparam ADDR_CH4 = 4'h8;
    localparam ADDR_CH_SEL = 4'hA;
    localparam ADDR_SELECTED = 4'hC;

    // Channel registers
    reg [DATA_WIDTH-1:0] reg_ch0, reg_ch1, reg_ch2, reg_ch3, reg_ch4;
    reg [2:0]            reg_channel_sel;
    reg [DATA_WIDTH-1:0] mux_selected_reg;
    wire [DATA_WIDTH-1:0] mux_selected_comb;

    // Write state
    reg                   aw_en;

    // Forward-retimed handshake signals for write address/data
    reg [ADDR_WIDTH-1:0]  awaddr_reg;
    reg                   awvalid_reg;
    reg [DATA_WIDTH-1:0]  wdata_reg;
    reg [(DATA_WIDTH/8)-1:0] wstrb_reg;
    reg                   wvalid_reg;
    reg                   arvalid_reg;
    reg [ADDR_WIDTH-1:0]  araddr_reg;

    // Pipeline stage for write address and data input
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            awaddr_reg   <= {ADDR_WIDTH{1'b0}};
            awvalid_reg  <= 1'b0;
            wdata_reg    <= {DATA_WIDTH{1'b0}};
            wstrb_reg    <= {(DATA_WIDTH/8){1'b0}};
            wvalid_reg   <= 1'b0;
        end else begin
            // Latch address and data when handshake occurs
            if (s_axi_awvalid && s_axi_wvalid && aw_en && ~awvalid_reg && ~wvalid_reg) begin
                awaddr_reg   <= s_axi_awaddr;
                awvalid_reg  <= 1'b1;
                wdata_reg    <= s_axi_wdata;
                wstrb_reg    <= s_axi_wstrb;
                wvalid_reg   <= 1'b1;
            end else if (s_axi_bready && s_axi_bvalid) begin
                awvalid_reg  <= 1'b0;
                wvalid_reg   <= 1'b0;
            end
        end
    end

    // Write Address handshake (now after retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (~s_axi_awready && awvalid_reg && wvalid_reg && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en         <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en         <= 1'b1;
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // Write Data handshake (now after retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && wvalid_reg && awvalid_reg && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Write Logic (now after retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            reg_ch0        <= {DATA_WIDTH{1'b0}};
            reg_ch1        <= {DATA_WIDTH{1'b0}};
            reg_ch2        <= {DATA_WIDTH{1'b0}};
            reg_ch3        <= {DATA_WIDTH{1'b0}};
            reg_ch4        <= {DATA_WIDTH{1'b0}};
            reg_channel_sel<= 3'b000;
        end else begin
            if (s_axi_awready && awvalid_reg && s_axi_wready && wvalid_reg) begin
                case (awaddr_reg)
                    ADDR_CH0: begin
                        if (wstrb_reg[1]) reg_ch0[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_ch0[7:0]  <= wdata_reg[7:0];
                    end
                    ADDR_CH1: begin
                        if (wstrb_reg[1]) reg_ch1[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_ch1[7:0]  <= wdata_reg[7:0];
                    end
                    ADDR_CH2: begin
                        if (wstrb_reg[1]) reg_ch2[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_ch2[7:0]  <= wdata_reg[7:0];
                    end
                    ADDR_CH3: begin
                        if (wstrb_reg[1]) reg_ch3[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_ch3[7:0]  <= wdata_reg[7:0];
                    end
                    ADDR_CH4: begin
                        if (wstrb_reg[1]) reg_ch4[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_ch4[7:0]  <= wdata_reg[7:0];
                    end
                    ADDR_CH_SEL: begin
                        reg_channel_sel <= wdata_reg[2:0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Write Response
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && awvalid_reg && s_axi_wready && wvalid_reg && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY response
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Pipeline stage for read address input (retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            araddr_reg   <= {ADDR_WIDTH{1'b0}};
            arvalid_reg  <= 1'b0;
        end else begin
            if (s_axi_arvalid && ~arvalid_reg) begin
                araddr_reg  <= s_axi_araddr;
                arvalid_reg <= 1'b1;
            end else if (s_axi_rready && s_axi_rvalid) begin
                arvalid_reg <= 1'b0;
            end
        end
    end

    // Read Address handshake (now after retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && arvalid_reg) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // MUX logic (combinational)
    assign mux_selected_comb = (reg_channel_sel == 3'b000) ? reg_ch0 :
                               (reg_channel_sel == 3'b001) ? reg_ch1 :
                               (reg_channel_sel == 3'b010) ? reg_ch2 :
                               (reg_channel_sel == 3'b011) ? reg_ch3 :
                               (reg_channel_sel == 3'b100) ? reg_ch4 :
                               16'h0000;

    // Pipeline mux output for timing balance
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            mux_selected_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            mux_selected_reg <= mux_selected_comb;
        end
    end

    // Read Logic (now after retiming)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
        end else begin
            if (s_axi_arready && arvalid_reg && ~s_axi_rvalid) begin
                case (araddr_reg)
                    ADDR_CH0:      s_axi_rdata <= reg_ch0;
                    ADDR_CH1:      s_axi_rdata <= reg_ch1;
                    ADDR_CH2:      s_axi_rdata <= reg_ch2;
                    ADDR_CH3:      s_axi_rdata <= reg_ch3;
                    ADDR_CH4:      s_axi_rdata <= reg_ch4;
                    ADDR_CH_SEL:   s_axi_rdata <= {13'b0, reg_channel_sel};
                    ADDR_SELECTED: s_axi_rdata <= mux_selected_reg;
                    default:       s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
                s_axi_rresp  <= 2'b00; // OKAY response
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule