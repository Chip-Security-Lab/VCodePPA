//SystemVerilog
module rng_hash_15_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   rst_n,
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

    // AXI4-Lite address map
    localparam ADDR_ENABLE = 4'h0;
    localparam ADDR_OUTV   = 4'h4;

    // Internal registers
    reg        enable_reg;
    reg [7:0]  out_v_reg;

    // AXI4-Lite handshake signals
    reg        awready_reg;
    reg        wready_reg;
    reg        bvalid_reg;
    reg [1:0]  bresp_reg;
    reg        arready_reg;
    reg        rvalid_reg;
    reg [7:0]  rdata_reg;
    reg [1:0]  rresp_reg;

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = rresp_reg;

    // Write address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg <= 1'b0;
        end else begin
            if (!awready_reg && s_axi_awvalid && s_axi_wvalid) begin
                awready_reg <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_reg <= 1'b0;
        end else begin
            if (!wready_reg && s_axi_wvalid && s_axi_awvalid) begin
                wready_reg <= 1'b1;
            end else begin
                wready_reg <= 1'b0;
            end
        end
    end

    // Write response channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && wready_reg && !bvalid_reg) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY response
            end else if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= 1'b0;
        end else begin
            if (awready_reg && wready_reg) begin
                case (s_axi_awaddr[ADDR_WIDTH-1:0])
                    ADDR_ENABLE: if (s_axi_wstrb[0]) enable_reg <= s_axi_wdata[0];
                    default: ;
                endcase
            end
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b0;
        end else begin
            if (!arready_reg && s_axi_arvalid) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 8'b0;
            rresp_reg  <= 2'b00;
        end else begin
            if (arready_reg && !rvalid_reg) begin
                rvalid_reg <= 1'b1;
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    ADDR_ENABLE: begin
                        rdata_reg <= {7'b0, enable_reg};
                        rresp_reg <= 2'b00; // OKAY response
                    end
                    ADDR_OUTV: begin
                        rdata_reg <= out_v_reg;
                        rresp_reg <= 2'b00; // OKAY response
                    end
                    default: begin
                        rdata_reg <= 8'b0;
                        rresp_reg <= 2'b10; // SLVERR response
                    end
                endcase
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    // Core function: out_v register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v_reg <= 8'hD2;
        end else begin
            case (enable_reg)
                1'b1: out_v_reg <= {out_v_reg[6:0], ^(out_v_reg & 8'hA3)};
                1'b0: out_v_reg <= out_v_reg;
                default: out_v_reg <= out_v_reg;
            endcase
        end
    end

endmodule