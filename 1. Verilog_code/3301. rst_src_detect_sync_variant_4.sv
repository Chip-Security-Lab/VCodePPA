//SystemVerilog
module rst_src_detect_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,
    // Standard Inputs
    input  wire                     por_n,
    input  wire                     wdt_n,
    input  wire                     ext_n,
    input  wire                     sw_n
);

    // Internal registers for sampled and processed signals
    reg        por_n_stage1, wdt_n_stage1, ext_n_stage1, sw_n_stage1;
    reg        valid_stage1;
    reg [3:0]  rst_src_stage2;
    reg        valid_stage2;
    reg [3:0]  rst_src;
    reg        valid_out;

    // AXI4-Lite internal registers
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg                  aw_hs;
    reg                  w_hs;
    reg                  ar_hs;

    // Stage 1: Sample and invert input signals, generate valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            por_n_stage1  <= 1'b1;
            wdt_n_stage1  <= 1'b1;
            ext_n_stage1  <= 1'b1;
            sw_n_stage1   <= 1'b1;
            valid_stage1  <= 1'b0;
        end else begin
            por_n_stage1  <= por_n;
            wdt_n_stage1  <= wdt_n;
            ext_n_stage1  <= ext_n;
            sw_n_stage1   <= sw_n;
            valid_stage1  <= 1'b1;
        end
    end

    // Stage 2: Invert and pack into rst_src
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_src_stage2 <= 4'b0000;
            valid_stage2   <= 1'b0;
        end else begin
            rst_src_stage2[0] <= ~por_n_stage1;
            rst_src_stage2[1] <= ~wdt_n_stage1;
            rst_src_stage2[2] <= ~ext_n_stage1;
            rst_src_stage2[3] <= ~sw_n_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_src   <= 4'b0000;
            valid_out <= 1'b0;
        end else begin
            rst_src   <= rst_src_stage2;
            valid_out <= valid_stage2;
        end
    end

    // AXI4-Lite Write Address Handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            awaddr_reg    <= {ADDR_WIDTH{1'b0}};
            aw_hs         <= 1'b0;
        end else begin
            if (!s_axi_awready && s_axi_awvalid)
                s_axi_awready <= 1'b1;
            else
                s_axi_awready <= 1'b0;

            if (!aw_hs && s_axi_awvalid && s_axi_awready) begin
                awaddr_reg <= s_axi_awaddr;
                aw_hs      <= 1'b1;
            end else if (b_handshake) begin
                aw_hs      <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Data Handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            w_hs         <= 1'b0;
        end else begin
            if (!s_axi_wready && s_axi_wvalid)
                s_axi_wready <= 1'b1;
            else
                s_axi_wready <= 1'b0;

            if (!w_hs && s_axi_wvalid && s_axi_wready) begin
                w_hs <= 1'b1;
            end else if (b_handshake) begin
                w_hs <= 1'b0;
            end
        end
    end

    // Write response logic
    wire write_en = aw_hs && w_hs && !b_handshake;
    wire b_handshake = s_axi_bvalid && s_axi_bready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (write_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address Handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            araddr_reg    <= {ADDR_WIDTH{1'b0}};
            ar_hs         <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid)
                s_axi_arready <= 1'b1;
            else
                s_axi_arready <= 1'b0;

            if (!ar_hs && s_axi_arvalid && s_axi_arready) begin
                araddr_reg <= s_axi_araddr;
                ar_hs      <= 1'b1;
            end else if (r_handshake) begin
                ar_hs      <= 1'b0;
            end
        end
    end

    // Read data logic
    wire r_handshake = s_axi_rvalid && s_axi_rready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ar_hs && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (araddr_reg[3:0])
                    4'h0: s_axi_rdata <= {28'b0, rst_src};     // rst_src at 0x0
                    4'h4: s_axi_rdata <= {31'b0, valid_out};   // valid_out at 0x4
                    default: s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write operation (no writable registers in original, dummy logic for PPA)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // No writable registers to reset
        end else if (write_en) begin
            // No writable registers to update
        end
    end

endmodule