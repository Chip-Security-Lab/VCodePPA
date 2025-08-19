//SystemVerilog
module hex2ascii_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [7:0]            s_axi_wdata,
    input  wire [0:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [7:0]             s_axi_rdata,
    output reg [1:0]             s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // Internal registers for memory-mapped interface
    reg  [3:0] hex_input_reg;
    reg  [7:0] ascii_output_reg;

    // AXI4-Lite address map
    localparam ADDR_HEX_INPUT   = 4'h0;
    localparam ADDR_ASCII_OUTPUT= 4'h4;

    // Write address handshake
    wire write_addr_handshake, write_data_handshake;
    assign write_addr_handshake = s_axi_awvalid & s_axi_awready;
    assign write_data_handshake = s_axi_wvalid  & s_axi_wready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
        end else if (!s_axi_awready && s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
        end else begin
            s_axi_awready <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
        end else if (!s_axi_wready && s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
        end else begin
            s_axi_wready <= 1'b0;
        end
    end

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hex_input_reg <= 4'b0000;
        end else if (write_addr_handshake && write_data_handshake) begin
            if (s_axi_awaddr[3:0] == ADDR_HEX_INPUT) begin
                hex_input_reg <= s_axi_wdata[3:0];
            end
        end
    end

    // Write response channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else if (write_addr_handshake && write_data_handshake) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00; // OKAY
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
        end else if (!s_axi_arready && s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
        end else begin
            s_axi_arready <= 1'b0;
        end
    end

    // Optimized combinational logic for ascii_output_reg
    always @(*) begin
        // Use range check and hardware-friendly expression
        ascii_output_reg = (hex_input_reg[3] == 1'b0 && hex_input_reg <= 4'd9) ?
                           (hex_input_reg + 8'h30) :
                           (hex_input_reg + 8'h37);
    end

    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 8'b0;
            s_axi_rresp  <= 2'b00;
        end else if (s_axi_arready && s_axi_arvalid) begin
            s_axi_rvalid <= 1'b1;
            case (s_axi_araddr[3:0])
                ADDR_HEX_INPUT:    s_axi_rdata <= {4'b0, hex_input_reg};
                ADDR_ASCII_OUTPUT: s_axi_rdata <= ascii_output_reg;
                default:           s_axi_rdata <= 8'b0;
            endcase
            s_axi_rresp <= 2'b00; // OKAY
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end

endmodule