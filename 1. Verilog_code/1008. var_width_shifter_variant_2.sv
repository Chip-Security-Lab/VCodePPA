//SystemVerilog
// Top-level module: AXI4-Lite variable-width shifter
module var_width_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4, // 16 bytes address space
    parameter DATA_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETN,

    // AXI4-Lite Slave Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_AWADDR,
    input  wire                   S_AXI_AWVALID,
    output reg                    S_AXI_AWREADY,

    // AXI4-Lite Slave Write Data Channel
    input  wire [DATA_WIDTH-1:0]  S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                   S_AXI_WVALID,
    output reg                    S_AXI_WREADY,

    // AXI4-Lite Slave Write Response Channel
    output reg  [1:0]             S_AXI_BRESP,
    output reg                    S_AXI_BVALID,
    input  wire                   S_AXI_BREADY,

    // AXI4-Lite Slave Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_ARADDR,
    input  wire                   S_AXI_ARVALID,
    output reg                    S_AXI_ARREADY,

    // AXI4-Lite Slave Read Data Channel
    output reg [DATA_WIDTH-1:0]   S_AXI_RDATA,
    output reg [1:0]              S_AXI_RRESP,
    output reg                    S_AXI_RVALID,
    input  wire                   S_AXI_RREADY
);

    // Internal Registers
    reg [DATA_WIDTH-1:0] reg_data;        // Input data register
    reg [1:0]            reg_width_sel;   // Width select register
    reg [4:0]            reg_shift_amt;   // Shift amount register
    reg                  reg_shift_left;  // Shift direction register
    reg [DATA_WIDTH-1:0] reg_result;      // Output result register

    // AXI4-Lite Address Map
    localparam ADDR_DATA      = 4'h0;
    localparam ADDR_WIDTH_SEL = 4'h4;
    localparam ADDR_SHIFT_AMT = 4'h8;
    localparam ADDR_SHIFT_LFT = 4'hC;
    localparam ADDR_RESULT    = 4'h10;

    // Internal AXI Write FSM
    reg [1:0] axi_wrstate;
    localparam WR_IDLE = 2'd0,
               WR_DATA = 2'd1,
               WR_RESP = 2'd2;

    // Internal AXI Read FSM
    reg [1:0] axi_rdstate;
    localparam RD_IDLE = 2'd0,
               RD_DATA = 2'd1;

    // Write Address/Data Latch
    reg [ADDR_WIDTH-1:0] axi_awaddr_latched;

    // Signals for submodules
    wire [DATA_WIDTH-1:0] masked_data;
    wire [DATA_WIDTH-1:0] shifted_data;

    // Write FSM
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            axi_wrstate         <= WR_IDLE;
            S_AXI_AWREADY       <= 1'b0;
            S_AXI_WREADY        <= 1'b0;
            S_AXI_BVALID        <= 1'b0;
            S_AXI_BRESP         <= 2'b00;
            axi_awaddr_latched  <= {ADDR_WIDTH{1'b0}};
        end else begin
            case (axi_wrstate)
                WR_IDLE: begin
                    S_AXI_AWREADY <= 1'b1;
                    S_AXI_WREADY  <= 1'b1;
                    S_AXI_BVALID  <= 1'b0;
                    if (S_AXI_AWVALID && S_AXI_WVALID) begin
                        axi_awaddr_latched <= S_AXI_AWADDR;
                        S_AXI_AWREADY <= 1'b0;
                        S_AXI_WREADY  <= 1'b0;
                        axi_wrstate   <= WR_RESP;
                    end
                end
                WR_RESP: begin
                    S_AXI_BVALID  <= 1'b1;
                    S_AXI_BRESP   <= 2'b00;
                    if (S_AXI_BREADY && S_AXI_BVALID) begin
                        S_AXI_BVALID <= 1'b0;
                        axi_wrstate  <= WR_IDLE;
                    end
                end
                default: begin
                    axi_wrstate <= WR_IDLE;
                end
            endcase
        end
    end

    // Write to Registers
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            reg_data       <= {DATA_WIDTH{1'b0}};
            reg_width_sel  <= 2'b00;
            reg_shift_amt  <= 5'b00000;
            reg_shift_left <= 1'b0;
        end else if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
            case (S_AXI_AWADDR[ADDR_WIDTH-1:0])
                ADDR_DATA: begin
                    if (S_AXI_WSTRB[3]) reg_data[31:24] <= S_AXI_WDATA[31:24];
                    if (S_AXI_WSTRB[2]) reg_data[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[1]) reg_data[15:8]  <= S_AXI_WDATA[15:8];
                    if (S_AXI_WSTRB[0]) reg_data[7:0]   <= S_AXI_WDATA[7:0];
                end
                ADDR_WIDTH_SEL: begin
                    if (S_AXI_WSTRB[0]) reg_width_sel <= S_AXI_WDATA[1:0];
                end
                ADDR_SHIFT_AMT: begin
                    if (S_AXI_WSTRB[0]) reg_shift_amt <= S_AXI_WDATA[4:0];
                end
                ADDR_SHIFT_LFT: begin
                    if (S_AXI_WSTRB[0]) reg_shift_left <= S_AXI_WDATA[0];
                end
                default: ;
            endcase
        end
    end

    // Read FSM
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            axi_rdstate    <= RD_IDLE;
            S_AXI_ARREADY  <= 1'b0;
            S_AXI_RVALID   <= 1'b0;
            S_AXI_RRESP    <= 2'b00;
            S_AXI_RDATA    <= {DATA_WIDTH{1'b0}};
        end else begin
            case (axi_rdstate)
                RD_IDLE: begin
                    S_AXI_ARREADY <= 1'b1;
                    S_AXI_RVALID  <= 1'b0;
                    if (S_AXI_ARVALID && S_AXI_ARREADY) begin
                        S_AXI_ARREADY <= 1'b0;
                        S_AXI_RVALID  <= 1'b1;
                        case (S_AXI_ARADDR[ADDR_WIDTH-1:0])
                            ADDR_DATA:       S_AXI_RDATA <= reg_data;
                            ADDR_WIDTH_SEL:  S_AXI_RDATA <= {30'b0, reg_width_sel};
                            ADDR_SHIFT_AMT:  S_AXI_RDATA <= {27'b0, reg_shift_amt};
                            ADDR_SHIFT_LFT:  S_AXI_RDATA <= {31'b0, reg_shift_left};
                            ADDR_RESULT:     S_AXI_RDATA <= reg_result;
                            default:         S_AXI_RDATA <= 32'hDEADBEEF;
                        endcase
                        S_AXI_RRESP   <= 2'b00;
                        axi_rdstate   <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (S_AXI_RVALID && S_AXI_RREADY) begin
                        S_AXI_RVALID  <= 1'b0;
                        axi_rdstate   <= RD_IDLE;
                    end
                end
                default: begin
                    axi_rdstate <= RD_IDLE;
                end
            endcase
        end
    end

    // Masking submodule instance
    data_masker u_data_masker (
        .data_in    (reg_data),
        .width_sel  (reg_width_sel),
        .data_out   (masked_data)
    );

    // Shifting submodule instance
    data_shifter u_data_shifter (
        .data_in    (masked_data),
        .shift_amt  (reg_shift_amt),
        .shift_left (reg_shift_left),
        .data_out   (shifted_data)
    );

    // Output result register with synchronous reset
    always @(posedge ACLK) begin
        if (!ARESETN)
            reg_result <= {DATA_WIDTH{1'b0}};
        else
            reg_result <= shifted_data;
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Data Masker
// Function: Masks input data according to the width selection signal
// -----------------------------------------------------------------------------
module data_masker(
    input  wire [31:0] data_in,
    input  wire [1:0]  width_sel,
    output reg  [31:0] data_out
);
    always @(*) begin
        case (width_sel)
            2'b00: data_out = {24'b0, data_in[7:0]};     // 8-bit mode
            2'b01: data_out = {16'b0, data_in[15:0]};    // 16-bit mode
            2'b10: data_out = {8'b0, data_in[23:0]};     // 24-bit mode
            default: data_out = data_in;                 // 32-bit mode
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Data Shifter
// Function: Performs left or right shift on input data by shift_amt
// -----------------------------------------------------------------------------
module data_shifter(
    input  wire [31:0] data_in,
    input  wire [4:0]  shift_amt,
    input  wire        shift_left,
    output reg  [31:0] data_out
);
    always @(*) begin
        if (shift_left)
            data_out = data_in << shift_amt;
        else
            data_out = data_in >> shift_amt;
    end
endmodule