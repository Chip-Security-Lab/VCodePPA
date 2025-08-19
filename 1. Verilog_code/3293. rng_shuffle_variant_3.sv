//SystemVerilog
module rng_shuffle_13_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   rst,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [7:0]            s_axi_wdata,
    input  [0:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output [1:0]            s_axi_bresp,
    output                  s_axi_bvalid,
    input                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output [7:0]            s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // Address Map
    localparam ADDR_RAND      = 4'h0;
    localparam ADDR_CONTROL   = 4'h4;

    // Internal Registers
    reg [7:0] rand_reg;
    reg       enable_reg;

    // AXI4-Lite Write FSM
    reg       awready_reg;
    reg       wready_reg;
    reg [1:0] bresp_reg;
    reg       bvalid_reg;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    wire      write_en;
    wire      aw_hs;
    wire      w_hs;

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_bvalid  = bvalid_reg;

    assign aw_hs = s_axi_awvalid & awready_reg;
    assign w_hs  = s_axi_wvalid  & wready_reg;
    assign write_en = aw_hs & w_hs;

    // AXI4-Lite Read FSM
    reg       arready_reg;
    reg [7:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg       rvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    wire      ar_hs;

    assign s_axi_arready = arready_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = rresp_reg;
    assign s_axi_rvalid  = rvalid_reg;

    assign ar_hs = s_axi_arvalid & arready_reg;

    // Write Address Channel Control
    always @(posedge clk) begin
        if (rst) begin
            awready_reg <= 1'b1;
        end else if (awready_reg && s_axi_awvalid) begin
            awready_reg <= 1'b0;
        end else if (bvalid_reg && s_axi_bready) begin
            awready_reg <= 1'b1;
        end
    end

    // Write Address Latching
    always @(posedge clk) begin
        if (rst) begin
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
        end else if (awready_reg && s_axi_awvalid) begin
            awaddr_reg <= s_axi_awaddr;
        end
    end

    // Write Data Channel Control
    always @(posedge clk) begin
        if (rst) begin
            wready_reg <= 1'b1;
        end else if (wready_reg && s_axi_wvalid) begin
            wready_reg <= 1'b0;
        end else if (bvalid_reg && s_axi_bready) begin
            wready_reg <= 1'b1;
        end
    end

    // Write Response Channel Control
    always @(posedge clk) begin
        if (rst) begin
            bvalid_reg <= 1'b0;
        end else if (write_en) begin
            bvalid_reg <= 1'b1;
        end else if (bvalid_reg && s_axi_bready) begin
            bvalid_reg <= 1'b0;
        end
    end

    // Write Response Code
    always @(posedge clk) begin
        if (rst) begin
            bresp_reg <= 2'b00;
        end else if (write_en) begin
            bresp_reg <= 2'b00; // OKAY
        end
    end

    // Write Operation - enable_reg
    always @(posedge clk) begin
        if (rst) begin
            enable_reg <= 1'b0;
        end else if (write_en) begin
            if (awaddr_reg == ADDR_CONTROL) begin
                if (s_axi_wstrb[0])
                    enable_reg <= s_axi_wdata[0];
            end
        end
    end

    // Read Address Channel Control
    always @(posedge clk) begin
        if (rst) begin
            arready_reg <= 1'b1;
        end else if (arready_reg && s_axi_arvalid) begin
            arready_reg <= 1'b0;
        end else if (rvalid_reg && s_axi_rready) begin
            arready_reg <= 1'b1;
        end
    end

    // Read Address Latching
    always @(posedge clk) begin
        if (rst) begin
            araddr_reg <= {ADDR_WIDTH{1'b0}};
        end else if (arready_reg && s_axi_arvalid) begin
            araddr_reg <= s_axi_araddr;
        end
    end

    // Read Data Valid Control
    always @(posedge clk) begin
        if (rst) begin
            rvalid_reg <= 1'b0;
        end else if (ar_hs) begin
            rvalid_reg <= 1'b1;
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end

    // Read Data Output
    always @(posedge clk) begin
        if (rst) begin
            rdata_reg <= 8'h00;
        end else if (ar_hs) begin
            case (s_axi_araddr)
                ADDR_RAND:    rdata_reg <= rand_reg;
                ADDR_CONTROL: rdata_reg <= {7'b0, enable_reg};
                default:      rdata_reg <= 8'h00;
            endcase
        end
    end

    // Read Response Code
    always @(posedge clk) begin
        if (rst) begin
            rresp_reg <= 2'b00;
        end else if (ar_hs) begin
            rresp_reg <= 2'b00; // OKAY
        end
    end

    // Main RNG Logic
    always @(posedge clk) begin
        if (rst) begin
            rand_reg <= 8'hC3;
        end else if (enable_reg) begin
            rand_reg <= {rand_reg[3:0], rand_reg[7:4]} ^ {4'h9, 4'h6};
        end
    end

endmodule