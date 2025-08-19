//SystemVerilog
module lsl_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire         ACLK,
    input  wire         ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0] AWADDR,
    input  wire                  AWVALID,
    output wire                  AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [7:0]            WDATA,
    input  wire [0:0]            WSTRB,
    input  wire                  WVALID,
    output wire                  WREADY,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]            BRESP,
    output reg                   BVALID,
    input  wire                  BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0] ARADDR,
    input  wire                  ARVALID,
    output wire                  ARREADY,

    // AXI4-Lite Read Data Channel
    output reg  [7:0]            RDATA,
    output reg  [1:0]            RRESP,
    output reg                   RVALID,
    input  wire                  RREADY
);

    // Address Map
    localparam ADDR_DATA_IN   = 4'h0;
    localparam ADDR_SHIFT_AMT = 4'h4;
    localparam ADDR_ENABLE    = 4'h8;
    localparam ADDR_DATA_OUT  = 4'hC;

    // Internal registers
    reg [7:0]  reg_data_in;
    reg [2:0]  reg_shift_amt;
    reg        reg_enable;
    reg [7:0]  reg_data_out;

    // Write FSM
    reg awready_reg, wready_reg;
    assign AWREADY = awready_reg;
    assign WREADY  = wready_reg;

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg                  write_en;

    // Read FSM
    reg arready_reg;
    assign ARREADY = arready_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg                  read_en;

    // AXI4-Lite Write Address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            awready_reg <= 1'b1;
            awaddr_reg  <= {ADDR_WIDTH{1'b0}};
        end else if (AWVALID && awready_reg) begin
            awready_reg <= 1'b0;
            awaddr_reg  <= AWADDR;
        end else if (BVALID && BREADY) begin
            awready_reg <= 1'b1;
        end
    end

    // AXI4-Lite Write Data handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            wready_reg <= 1'b1;
        end else if (WVALID && wready_reg) begin
            wready_reg <= 1'b0;
        end else if (BVALID && BREADY) begin
            wready_reg <= 1'b1;
        end
    end

    assign write_en = AWVALID && awready_reg && WVALID && wready_reg;

    // AXI4-Lite Write
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            reg_data_in   <= 8'b0;
            reg_shift_amt <= 3'b0;
            reg_enable    <= 1'b0;
        end else if (write_en) begin
            case (awaddr_reg)
                ADDR_DATA_IN:   if (WSTRB[0]) reg_data_in   <= WDATA;
                ADDR_SHIFT_AMT: if (WSTRB[0]) reg_shift_amt <= WDATA[2:0];
                ADDR_ENABLE:    if (WSTRB[0]) reg_enable    <= WDATA[0];
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00;
        end else if (write_en) begin
            BVALID <= 1'b1;
            BRESP  <= 2'b00; // OKAY
        end else if (BVALID && BREADY) begin
            BVALID <= 1'b0;
        end
    end

    // AXI4-Lite Read Address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            arready_reg <= 1'b1;
            araddr_reg  <= {ADDR_WIDTH{1'b0}};
        end else if (ARVALID && arready_reg) begin
            arready_reg <= 1'b0;
            araddr_reg  <= ARADDR;
        end else if (RVALID && RREADY) begin
            arready_reg <= 1'b1;
        end
    end

    assign read_en = ARVALID && arready_reg;

    // AXI4-Lite Read
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            RVALID <= 1'b0;
            RDATA  <= 8'b0;
            RRESP  <= 2'b00;
        end else if (read_en) begin
            RVALID <= 1'b1;
            case (ARADDR)
                ADDR_DATA_IN:   RDATA <= reg_data_in;
                ADDR_SHIFT_AMT: RDATA <= {5'b0, reg_shift_amt};
                ADDR_ENABLE:    RDATA <= {7'b0, reg_enable};
                ADDR_DATA_OUT:  RDATA <= reg_data_out;
                default:        RDATA <= 8'b0;
            endcase
            RRESP <= 2'b00;
        end else if (RVALID && RREADY) begin
            RVALID <= 1'b0;
        end
    end

    // LSL Shifter core logic
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            reg_data_out <= 8'b0;
        end else if (reg_enable) begin
            reg_data_out <= reg_data_in << reg_shift_amt;
        end
    end

endmodule