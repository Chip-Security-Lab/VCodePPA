//SystemVerilog
module ascii_dec_to_bin_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire             ACLK,
    input  wire             ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire                    AWVALID,
    output reg                     AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [7:0]              WDATA,
    input  wire [0:0]              WSTRB,
    input  wire                    WVALID,
    output reg                     WREADY,

    // AXI4-Lite Write Response Channel
    output reg [1:0]               BRESP,
    output reg                     BVALID,
    input  wire                    BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]   ARADDR,
    input  wire                    ARVALID,
    output reg                     ARREADY,

    // AXI4-Lite Read Data Channel
    output reg [7:0]               RDATA,
    output reg [1:0]               RRESP,
    output reg                     RVALID,
    input  wire                    RREADY
);

    // Internal registers for core logic
    reg  [7:0] ascii_char_reg;
    reg  [3:0] binary_out_reg;
    reg        valid_reg;

    // Internal state for AXI4-Lite handshake
    reg        write_addr_latched;
    reg        write_data_latched;
    reg        read_addr_latched;

    // Address mapping
    localparam ADDR_ASCII_CHAR = 4'h0;
    localparam ADDR_BINARY_OUT = 4'h4;
    localparam ADDR_VALID      = 4'h8;

    // Write Address Channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY <= 1'b0;
            write_addr_latched <= 1'b0;
        end else if (!AWREADY && AWVALID) begin
            AWREADY <= 1'b1;
            write_addr_latched <= 1'b1;
        end else begin
            AWREADY <= 1'b0;
            write_addr_latched <= 1'b0;
        end
    end

    // Write Data Channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            WREADY <= 1'b0;
            write_data_latched <= 1'b0;
        end else if (!WREADY && WVALID) begin
            WREADY <= 1'b1;
            write_data_latched <= 1'b1;
        end else begin
            WREADY <= 1'b0;
            write_data_latched <= 1'b0;
        end
    end

    // Write Operation
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ascii_char_reg <= 8'b0;
            BRESP <= 2'b00;
            BVALID <= 1'b0;
        end else begin
            if (AWREADY && AWVALID && WREADY && WVALID) begin
                if (AWADDR[ADDR_WIDTH-1:0] == ADDR_ASCII_CHAR) begin
                    ascii_char_reg <= WDATA;
                end
                BRESP <= 2'b00; // OKAY response
                BVALID <= 1'b1;
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // Read Address Channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 1'b0;
            read_addr_latched <= 1'b0;
        end else if (!ARREADY && ARVALID) begin
            ARREADY <= 1'b1;
            read_addr_latched <= 1'b1;
        end else begin
            ARREADY <= 1'b0;
            read_addr_latched <= 1'b0;
        end
    end

    // Core logic: ascii_dec_to_bin functionality
    always @(*) begin
        if ((ascii_char_reg >= 8'h30) && (ascii_char_reg <= 8'h39)) begin
            binary_out_reg = ascii_char_reg - 8'h30;
            valid_reg = 1'b1;
        end else begin
            binary_out_reg = 4'b0000;
            valid_reg = 1'b0;
        end
    end

    // Read Data Channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            RDATA <= 8'b0;
            RRESP <= 2'b00;
            RVALID <= 1'b0;
        end else begin
            if (ARREADY && ARVALID) begin
                case (ARADDR[ADDR_WIDTH-1:0])
                    ADDR_ASCII_CHAR: RDATA <= ascii_char_reg;
                    ADDR_BINARY_OUT: RDATA <= {4'b0, binary_out_reg};
                    ADDR_VALID:      RDATA <= {7'b0, valid_reg};
                    default:         RDATA <= 8'b0;
                endcase
                RRESP <= 2'b00; // OKAY response
                RVALID <= 1'b1;
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

endmodule