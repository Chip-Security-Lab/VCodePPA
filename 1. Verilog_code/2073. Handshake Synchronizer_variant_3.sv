//SystemVerilog
module handshake_sync_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire                   AWVALID,
    output reg                    AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                   WVALID,
    output reg                    WREADY,

    // AXI4-Lite Write Response Channel
    output reg [1:0]              BRESP,
    output reg                    BVALID,
    input  wire                   BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  ARADDR,
    input  wire                   ARVALID,
    output reg                    ARREADY,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]   RDATA,
    output reg [1:0]              RRESP,
    output reg                    RVALID,
    input  wire                   RREADY
);

    // Internal registers for memory-mapped handshake logic
    reg req_a_reg;
    reg ack_b_reg;
    reg req_b_reg;
    reg ack_a_reg;

    // Synchronizer flops for handshake
    reg req_a_meta, req_a_sync;
    reg ack_b_meta, ack_b_sync;

    // Address parameters for mapped registers
    localparam ADDR_REQ_A = 4'h0;
    localparam ADDR_REQ_B = 4'h4;
    localparam ADDR_ACK_A = 4'h8;
    localparam ADDR_ACK_B = 4'hC;

    // Write state
    reg aw_en;

    // Write address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY <= 1'b0;
            aw_en   <= 1'b1;
        end else begin
            if (~AWREADY && AWVALID && aw_en) begin
                AWREADY <= 1'b1;
                aw_en   <= 1'b0;
            end else if (WREADY && WVALID) begin
                AWREADY <= 1'b0;
                aw_en   <= 1'b1;
            end else begin
                AWREADY <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            WREADY <= 1'b0;
        end else begin
            if (~WREADY && WVALID && AWREADY && AWVALID) begin
                WREADY <= 1'b1;
            end else begin
                WREADY <= 1'b0;
            end
        end
    end

    // Write to registers
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            req_a_reg  <= 1'b0;
            ack_b_reg  <= 1'b0;
        end else if (WREADY && WVALID && AWREADY && AWVALID) begin
            case (AWADDR)
                ADDR_REQ_A: req_a_reg <= WDATA[0];
                ADDR_ACK_B: ack_b_reg <= WDATA[0];
                default: ;
            endcase
        end
    end

    // Write response
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00;
        end else begin
            if (AWREADY && AWVALID && WREADY && WVALID && ~BVALID) begin
                BVALID <= 1'b1;
                BRESP  <= 2'b00;
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 1'b0;
        end else begin
            if (~ARREADY && ARVALID) begin
                ARREADY <= 1'b1;
            end else begin
                ARREADY <= 1'b0;
            end
        end
    end

    // Read logic
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            RVALID <= 1'b0;
            RRESP  <= 2'b00;
            RDATA  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ARREADY && ARVALID && ~RVALID) begin
                RVALID <= 1'b1;
                RRESP  <= 2'b00;
                case (ARADDR)
                    ADDR_REQ_A: RDATA <= { {DATA_WIDTH-1{1'b0}}, req_a_reg };
                    ADDR_REQ_B: RDATA <= { {DATA_WIDTH-1{1'b0}}, req_b_reg };
                    ADDR_ACK_A: RDATA <= { {DATA_WIDTH-1{1'b0}}, ack_a_reg };
                    ADDR_ACK_B: RDATA <= { {DATA_WIDTH-1{1'b0}}, ack_b_reg };
                    default:    RDATA <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

    // Handshake synchronization logic
    // Forward synchronization for req_a_reg to req_b_reg
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            req_a_meta <= 1'b0;
            req_a_sync <= 1'b0;
            req_b_reg  <= 1'b0;
        end else begin
            req_a_meta <= req_a_reg;
            req_a_sync <= req_a_meta;
            req_b_reg  <= req_a_sync;
        end
    end

    // Forward synchronization for ack_b_reg to ack_a_reg
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ack_b_meta <= 1'b0;
            ack_b_sync <= 1'b0;
            ack_a_reg  <= 1'b0;
        end else begin
            ack_b_meta <= ack_b_reg;
            ack_b_sync <= ack_b_meta;
            ack_a_reg  <= ack_b_sync;
        end
    end

endmodule