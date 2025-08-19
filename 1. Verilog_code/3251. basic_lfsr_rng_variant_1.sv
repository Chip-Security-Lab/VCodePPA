//SystemVerilog
module basic_lfsr_rng_axi4lite (
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [15:0]  s_axi_wdata,
    input  wire [1:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,

    // AXI4-Lite Read Data Channel
    output wire [15:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready
);

    // Internal Registers
    reg  [15:0] lfsr_reg;
    reg         lfsr_reg_ena;

    // AXI4-Lite handshake signals
    reg         awready_reg, wready_reg, bvalid_reg;
    reg         arready_reg, rvalid_reg;
    reg  [15:0] rdata_reg;
    reg  [3:0]  awaddr_reg, araddr_reg;

    // Write Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            awready_reg <= 1'b0;
        else if (!awready_reg && s_axi_awvalid && s_axi_wvalid)
            awready_reg <= 1'b1;
        else
            awready_reg <= 1'b0;
    end
    assign s_axi_awready = awready_reg;

    // Write Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wready_reg <= 1'b0;
        else if (!wready_reg && s_axi_awvalid && s_axi_wvalid)
            wready_reg <= 1'b1;
        else
            wready_reg <= 1'b0;
    end
    assign s_axi_wready = wready_reg;

    // LFSR Write (Optional: allow software seed reload)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 16'hACE1;
        end else if (awready_reg && wready_reg) begin
            case (s_axi_awaddr[3:0])
                4'h0: begin
                    if (s_axi_wstrb[1]) lfsr_reg[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) lfsr_reg[7:0]  <= s_axi_wdata[7:0];
                end
                default: begin
                    lfsr_reg <= lfsr_reg;
                end
            endcase
        end else begin
            lfsr_reg <= {lfsr_reg[14:0], lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10]};
        end
    end

    // Write Response Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bvalid_reg <= 1'b0;
        else if (awready_reg && wready_reg)
            bvalid_reg <= 1'b1;
        else if (bvalid_reg && s_axi_bready)
            bvalid_reg <= 1'b0;
    end
    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_bresp  = 2'b00; // OKAY response

    // Read Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            arready_reg <= 1'b0;
        else if (!arready_reg && s_axi_arvalid)
            arready_reg <= 1'b1;
        else
            arready_reg <= 1'b0;
    end
    assign s_axi_arready = arready_reg;

    // Read Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 16'h0000;
        end else if (arready_reg && s_axi_arvalid) begin
            rvalid_reg <= 1'b1;
            case (s_axi_araddr[3:0])
                4'h0: rdata_reg <= lfsr_reg;
                default: rdata_reg <= 16'h0000;
            endcase
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rdata  = rdata_reg;
    assign s_axi_rresp  = 2'b00; // OKAY response

endmodule