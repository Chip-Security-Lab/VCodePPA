//SystemVerilog
module MultiResetDetector_AXI4Lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETN,
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire                   AWVALID,
    output wire                   AWREADY,
    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                   WVALID,
    output wire                   WREADY,
    // AXI4-Lite Write Response Channel
    output wire [1:0]             BRESP,
    output wire                   BVALID,
    input  wire                   BREADY,
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  ARADDR,
    input  wire                   ARVALID,
    output wire                   ARREADY,
    // AXI4-Lite Read Data Channel
    output wire [DATA_WIDTH-1:0]  RDATA,
    output wire [1:0]             RRESP,
    output wire                   RVALID,
    input  wire                   RREADY
);

    // Register address map
    localparam REG_SOFT_RST_ADDR        = 4'h0;
    localparam REG_RESET_DETECTED_ADDR  = 4'h4;

    // Internal registers
    reg soft_reset_reg;
    reg reset_detected_reg;
    reg rstn_sync_1, rstn_sync_2;
    reg soft_rst_sync_1, soft_rst_sync_2;

    // AXI4-Lite handshake signals
    reg awready_reg, wready_reg, arready_reg;
    reg write_en;
    reg read_en;

    // Pipeline registers for outputs (moved backward for retiming)
    reg [1:0] bresp_pipe;
    reg       bvalid_pipe;
    reg [DATA_WIDTH-1:0] rdata_pipe;
    reg [1:0] rresp_pipe;
    reg       rvalid_pipe;

    // Synchronize ARESETN
    wire rst_n = ARESETN;

    // Write address handshake
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            awready_reg <= 1'b0;
        else if (!awready_reg && AWVALID && WVALID)
            awready_reg <= 1'b1;
        else
            awready_reg <= 1'b0;
    end
    assign AWREADY = awready_reg;

    // Write data handshake
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            wready_reg <= 1'b0;
        else if (!wready_reg && AWVALID && WVALID)
            wready_reg <= 1'b1;
        else
            wready_reg <= 1'b0;
    end
    assign WREADY = wready_reg;

    // Write enable
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            write_en <= 1'b0;
        else
            write_en <= (AWVALID && WVALID && awready_reg && wready_reg);
    end

    // Pipeline for write response logic (move register backward for retiming)
    reg write_en_d;
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            write_en_d <= 1'b0;
        else
            write_en_d <= write_en;
    end

    wire bvalid_comb = write_en_d | (bvalid_pipe & ~BREADY);
    wire [1:0] bresp_comb = 2'b00; // Always OKAY

    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_pipe <= 1'b0;
            bresp_pipe  <= 2'b00;
        end else begin
            if (write_en_d) begin
                bvalid_pipe <= 1'b1;
                bresp_pipe  <= 2'b00;
            end else if (bvalid_pipe && BREADY) begin
                bvalid_pipe <= 1'b0;
                bresp_pipe  <= 2'b00;
            end
        end
    end
    assign BVALID = bvalid_pipe;
    assign BRESP  = bresp_pipe;

    // Read address handshake
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            arready_reg <= 1'b0;
        else if (!arready_reg && ARVALID)
            arready_reg <= 1'b1;
        else
            arready_reg <= 1'b0;
    end
    assign ARREADY = arready_reg;

    // Read enable
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n)
            read_en <= 1'b0;
        else
            read_en <= (ARVALID && arready_reg);
    end

    // Pipeline for read data and response (move register backward for retiming)
    reg read_en_d;
    reg [ADDR_WIDTH-1:0] araddr_d;
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            read_en_d <= 1'b0;
            araddr_d  <= {ADDR_WIDTH{1'b0}};
        end else begin
            read_en_d <= read_en;
            araddr_d  <= ARADDR;
        end
    end

    wire [DATA_WIDTH-1:0] rdata_comb =
        (araddr_d == REG_SOFT_RST_ADDR)       ? {{(DATA_WIDTH-1){1'b0}}, soft_reset_reg} :
        (araddr_d == REG_RESET_DETECTED_ADDR) ? {{(DATA_WIDTH-1){1'b0}}, reset_detected_reg} :
                                                 {DATA_WIDTH{1'b0}};
    wire [1:0] rresp_comb = 2'b00; // Always OKAY
    wire rvalid_comb = read_en_d | (rvalid_pipe & ~RREADY);

    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_pipe <= 1'b0;
            rdata_pipe  <= {DATA_WIDTH{1'b0}};
            rresp_pipe  <= 2'b00;
        end else begin
            if (read_en_d) begin
                rvalid_pipe <= 1'b1;
                rdata_pipe  <= rdata_comb;
                rresp_pipe  <= rresp_comb;
            end else if (rvalid_pipe && RREADY) begin
                rvalid_pipe <= 1'b0;
                rdata_pipe  <= {DATA_WIDTH{1'b0}};
                rresp_pipe  <= 2'b00;
            end
        end
    end
    assign RVALID = rvalid_pipe;
    assign RDATA  = rdata_pipe;
    assign RRESP  = rresp_pipe;

    // Write to internal registers
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            soft_reset_reg <= 1'b1;
        end else if (write_en) begin
            if (AWADDR[ADDR_WIDTH-1:0] == REG_SOFT_RST_ADDR) begin
                if (WSTRB[0]) // Only LSB valid
                    soft_reset_reg <= WDATA[0];
            end
        end
    end

    // Synchronize soft_rst and rst_n for reset_detected logic
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            rstn_sync_1      <= 1'b0;
            rstn_sync_2      <= 1'b0;
            soft_rst_sync_1  <= 1'b0;
            soft_rst_sync_2  <= 1'b0;
        end else begin
            rstn_sync_1      <= rst_n;
            rstn_sync_2      <= rstn_sync_1;
            soft_rst_sync_1  <= soft_reset_reg;
            soft_rst_sync_2  <= soft_rst_sync_1;
        end
    end

    // Core reset_detected logic
    always @(posedge ACLK or negedge rst_n) begin
        if (!rst_n || !soft_reset_reg)
            reset_detected_reg <= 1'b1;
        else
            reset_detected_reg <= 1'b0;
    end

endmodule