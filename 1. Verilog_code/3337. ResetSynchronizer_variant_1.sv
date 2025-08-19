//SystemVerilog
module ResetSynchronizer_AXI4Lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_AWADDR,
    input  wire                   S_AXI_AWVALID,
    output reg                    S_AXI_AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                   S_AXI_WVALID,
    output reg                    S_AXI_WREADY,

    // AXI4-Lite Write Response Channel
    output reg [1:0]              S_AXI_BRESP,
    output reg                    S_AXI_BVALID,
    input  wire                   S_AXI_BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_ARADDR,
    input  wire                   S_AXI_ARVALID,
    output reg                    S_AXI_ARREADY,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]   S_AXI_RDATA,
    output reg [1:0]              S_AXI_RRESP,
    output reg                    S_AXI_RVALID,
    input  wire                   S_AXI_RREADY
);

    // Internal registers for reset synchronizer logic
    reg rst_ff1_stage1;
    reg rst_ff2_stage2;
    reg rst_sync_stage3;

    // AXI4-Lite register map
    localparam integer REG_RST_SYNC_ADDR = 0;
    localparam integer REG_RST_CTRL_ADDR = 4;

    // Internal register for write access to reset synchronizer
    reg rst_ctrl_stage1;
    reg rst_ctrl_stage2;

    // Pipeline registers for handshakes and address/data
    reg awvalid_stage1, awvalid_stage2;
    reg [ADDR_WIDTH-1:0] awaddr_stage1, awaddr_stage2;
    reg wvalid_stage1, wvalid_stage2;
    reg [DATA_WIDTH-1:0] wdata_stage1, wdata_stage2;
    reg [(DATA_WIDTH/8)-1:0] wstrb_stage1, wstrb_stage2;

    reg arvalid_stage1, arvalid_stage2;
    reg [ADDR_WIDTH-1:0] araddr_stage1, araddr_stage2;

    // Pipeline registers for ready signals
    reg awready_stage1, awready_stage2;
    reg wready_stage1, wready_stage2;
    reg arready_stage1, arready_stage2;

    // Write address handshake pipeline
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awvalid_stage1 <= 1'b0;
            awaddr_stage1  <= {ADDR_WIDTH{1'b0}};
        end else begin
            awvalid_stage1 <= S_AXI_AWVALID;
            awaddr_stage1  <= S_AXI_AWADDR;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awvalid_stage2 <= 1'b0;
            awaddr_stage2  <= {ADDR_WIDTH{1'b0}};
        end else begin
            awvalid_stage2 <= awvalid_stage1;
            awaddr_stage2  <= awaddr_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            S_AXI_AWREADY <= 1'b0;
        else
            S_AXI_AWREADY <= ~awready_stage2 && awvalid_stage2 && wvalid_stage2;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            awready_stage1 <= 1'b0;
        else
            awready_stage1 <= ~awready_stage1 && awvalid_stage1 && wvalid_stage1;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            awready_stage2 <= 1'b0;
        else
            awready_stage2 <= awready_stage1;
    end

    // Write data handshake pipeline
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wvalid_stage1 <= 1'b0;
            wdata_stage1  <= {DATA_WIDTH{1'b0}};
            wstrb_stage1  <= {(DATA_WIDTH/8){1'b0}};
        end else begin
            wvalid_stage1 <= S_AXI_WVALID;
            wdata_stage1  <= S_AXI_WDATA;
            wstrb_stage1  <= S_AXI_WSTRB;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wvalid_stage2 <= 1'b0;
            wdata_stage2  <= {DATA_WIDTH{1'b0}};
            wstrb_stage2  <= {(DATA_WIDTH/8){1'b0}};
        end else begin
            wvalid_stage2 <= wvalid_stage1;
            wdata_stage2  <= wdata_stage1;
            wstrb_stage2  <= wstrb_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            S_AXI_WREADY <= 1'b0;
        else
            S_AXI_WREADY <= ~wready_stage2 && wvalid_stage2 && awvalid_stage2;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            wready_stage1 <= 1'b0;
        else
            wready_stage1 <= ~wready_stage1 && wvalid_stage1 && awvalid_stage1;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            wready_stage2 <= 1'b0;
        else
            wready_stage2 <= wready_stage1;
    end

    // Write response pipeline
    reg bvalid_stage1, bvalid_stage2;
    reg [1:0] bresp_stage1, bresp_stage2;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            bvalid_stage1 <= 1'b0;
            bresp_stage1  <= 2'b00;
        end else begin
            if (awready_stage2 && awvalid_stage2 && wready_stage2 && wvalid_stage2 && !bvalid_stage1) begin
                bvalid_stage1 <= 1'b1;
                bresp_stage1  <= 2'b00;
            end else if (bvalid_stage1 && S_AXI_BREADY) begin
                bvalid_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            bvalid_stage2 <= 1'b0;
            bresp_stage2  <= 2'b00;
        end else begin
            bvalid_stage2 <= bvalid_stage1;
            bresp_stage2  <= bresp_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00;
        end else begin
            S_AXI_BVALID <= bvalid_stage2;
            S_AXI_BRESP  <= bresp_stage2;
        end
    end

    // Write logic for reset control register with pipeline
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rst_ctrl_stage1 <= 1'b1;
        end else begin
            if (awready_stage2 && awvalid_stage2 && wready_stage2 && wvalid_stage2) begin
                if (awaddr_stage2[ADDR_WIDTH-1:0] == REG_RST_CTRL_ADDR)
                    rst_ctrl_stage1 <= wdata_stage2[0];
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            rst_ctrl_stage2 <= 1'b1;
        else
            rst_ctrl_stage2 <= rst_ctrl_stage1;
    end

    // Read address handshake pipeline
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            arvalid_stage1 <= 1'b0;
            araddr_stage1  <= {ADDR_WIDTH{1'b0}};
        end else begin
            arvalid_stage1 <= S_AXI_ARVALID;
            araddr_stage1  <= S_AXI_ARADDR;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            arvalid_stage2 <= 1'b0;
            araddr_stage2  <= {ADDR_WIDTH{1'b0}};
        end else begin
            arvalid_stage2 <= arvalid_stage1;
            araddr_stage2  <= araddr_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            S_AXI_ARREADY <= 1'b0;
        else
            S_AXI_ARREADY <= ~arready_stage2 && arvalid_stage2;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            arready_stage1 <= 1'b0;
        else
            arready_stage1 <= ~arready_stage1 && arvalid_stage1;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            arready_stage2 <= 1'b0;
        else
            arready_stage2 <= arready_stage1;
    end

    // Read data channel pipeline
    reg rvalid_stage1, rvalid_stage2;
    reg [1:0] rresp_stage1, rresp_stage2;
    reg [DATA_WIDTH-1:0] rdata_stage1, rdata_stage2;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rvalid_stage1 <= 1'b0;
            rresp_stage1  <= 2'b00;
            rdata_stage1  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (arready_stage2 && arvalid_stage2 && !rvalid_stage1) begin
                rvalid_stage1 <= 1'b1;
                rresp_stage1  <= 2'b00;
                case (araddr_stage2[ADDR_WIDTH-1:0])
                    REG_RST_SYNC_ADDR: rdata_stage1 <= {{(DATA_WIDTH-1){1'b0}}, rst_sync_stage3};
                    REG_RST_CTRL_ADDR: rdata_stage1 <= {{(DATA_WIDTH-1){1'b0}}, rst_ctrl_stage2};
                    default:           rdata_stage1 <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (rvalid_stage1 && S_AXI_RREADY) begin
                rvalid_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rvalid_stage2 <= 1'b0;
            rresp_stage2  <= 2'b00;
            rdata_stage2  <= {DATA_WIDTH{1'b0}};
        end else begin
            rvalid_stage2 <= rvalid_stage1;
            rresp_stage2  <= rresp_stage1;
            rdata_stage2  <= rdata_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RDATA  <= {DATA_WIDTH{1'b0}};
        end else begin
            S_AXI_RVALID <= rvalid_stage2;
            S_AXI_RRESP  <= rresp_stage2;
            S_AXI_RDATA  <= rdata_stage2;
        end
    end

    // Reset synchronizer logic using AXI4-Lite-controlled reset (deeper pipeline)
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rst_ff1_stage1   <= 1'b0;
            rst_ff2_stage2   <= 1'b0;
            rst_sync_stage3  <= 1'b0;
        end else begin
            rst_ff1_stage1   <= (rst_ctrl_stage2 == 1'b0) ? 1'b0 : 1'b1;
            rst_ff2_stage2   <= (rst_ctrl_stage2 == 1'b0) ? 1'b0 : rst_ff1_stage1;
            rst_sync_stage3  <= (rst_ctrl_stage2 == 1'b0) ? 1'b0 : rst_ff2_stage2;
        end
    end

endmodule