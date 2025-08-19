//SystemVerilog
module metastability_rng_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    // AXI4-Lite Slave Interface
    input  wire                  clk_sys,
    input  wire                  rst_n,

    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output wire                  s_axi_awready,

    // Write Data Channel
    input  wire [7:0]            s_axi_wdata,
    input  wire [0:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output wire                  s_axi_wready,

    // Write Response Channel
    output wire [1:0]            s_axi_bresp,
    output wire                  s_axi_bvalid,
    input  wire                  s_axi_bready,

    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output wire                  s_axi_arready,

    // Read Data Channel
    output wire [7:0]            s_axi_rdata,
    output wire [1:0]            s_axi_rresp,
    output wire                  s_axi_rvalid,
    input  wire                  s_axi_rready,

    // Metastability RNG clock
    input  wire                  meta_clk
);

    // AXI4-Lite interface signals
    reg                          awready_stage1, awready_stage2;
    reg                          wready_stage1, wready_stage2;
    reg                          arready_stage1, arready_stage2;

    assign s_axi_awready = awready_stage2;
    assign s_axi_wready  = wready_stage2;
    assign s_axi_arready = arready_stage2;

    // Core RNG logic with deeper pipelining
    reg meta_stage1, meta_stage2, meta_stage3;
    reg [7:0] random_stage1, random_stage2, random_stage3;
    reg [7:0] random_value_stage1, random_value_stage2;
    reg [7:0] random_value_reg_stage1, random_value_reg_stage2;

    // Metastable input using clock domain crossing (2FF synchronizer with one more stage for safety)
    always @(posedge meta_clk or negedge rst_n) begin
        if (!rst_n)
            meta_stage1 <= 1'b0;
        else
            meta_stage1 <= ~meta_stage1;
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            meta_stage2 <= 1'b0;
            meta_stage3 <= 1'b0;
        end else begin
            meta_stage2 <= meta_stage1;
            meta_stage3 <= meta_stage2;
        end
    end

    // Random value generation pipeline (split into more stages)
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_stage1 <= 8'h42;
        end else begin
            random_stage1 <= {random_stage1[6:0], meta_stage3 ^ random_stage1[7]};
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_stage2 <= 8'h42;
        end else begin
            random_stage2 <= random_stage1;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_stage3 <= 8'h42;
        end else begin
            random_stage3 <= random_stage2;
        end
    end

    // Pipeline for random_value
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value_stage1 <= 8'h42;
        end else begin
            random_value_stage1 <= random_stage3;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value_stage2 <= 8'h42;
        end else begin
            random_value_stage2 <= random_value_stage1;
        end
    end

    // Pipeline for AXI read random value
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value_reg_stage1 <= 8'h42;
        end else begin
            random_value_reg_stage1 <= random_value_stage2;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value_reg_stage2 <= 8'h42;
        end else begin
            random_value_reg_stage2 <= random_value_reg_stage1;
        end
    end

    // AXI4-Lite Write FSM Pipeline
    reg        axi_aw_en_stage1, axi_aw_en_stage2;
    reg [ADDR_WIDTH-1:0] awaddr_stage1, awaddr_stage2;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            awready_stage1 <= 1'b0;
            wready_stage1  <= 1'b0;
            axi_aw_en_stage1   <= 1'b1;
            awaddr_stage1  <= {ADDR_WIDTH{1'b0}};
        end else begin
            // Write Address handshake
            if (~awready_stage1 && s_axi_awvalid && axi_aw_en_stage1) begin
                awready_stage1 <= 1'b1;
                awaddr_stage1  <= s_axi_awaddr;
            end else if (s_axi_awvalid && awready_stage1 && s_axi_wvalid && wready_stage1) begin
                awready_stage1 <= 1'b0;
            end else begin
                awready_stage1 <= 1'b0;
            end

            // Write Data handshake
            if (~wready_stage1 && s_axi_wvalid && axi_aw_en_stage1) begin
                wready_stage1 <= 1'b1;
            end else if (s_axi_wvalid && wready_stage1 && s_axi_awvalid && awready_stage1) begin
                wready_stage1 <= 1'b0;
            end else begin
                wready_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            awready_stage2 <= 1'b0;
            wready_stage2  <= 1'b0;
            axi_aw_en_stage2   <= 1'b1;
            awaddr_stage2  <= {ADDR_WIDTH{1'b0}};
        end else begin
            awready_stage2 <= awready_stage1;
            wready_stage2  <= wready_stage1;
            axi_aw_en_stage2   <= axi_aw_en_stage1;
            awaddr_stage2  <= awaddr_stage1;
        end
    end

    // No writeable user registers (as original)
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            // No writeable user registers
        end else if (awready_stage2 && s_axi_awvalid && wready_stage2 && s_axi_wvalid) begin
            // No user register to write; could add control/status if needed
        end
    end

    // Write Response Generation with deeper pipelining
    reg s_axi_bvalid_stage1, s_axi_bvalid_stage2, s_axi_bvalid_stage3;
    reg [1:0] s_axi_bresp_stage1, s_axi_bresp_stage2, s_axi_bresp_stage3;
    reg axi_aw_en_resp_stage1, axi_aw_en_resp_stage2, axi_aw_en_resp_stage3;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid_stage1 <= 1'b0;
            s_axi_bresp_stage1  <= 2'b00;
            axi_aw_en_resp_stage1    <= 1'b1;
        end else begin
            if (awready_stage2 && s_axi_awvalid && wready_stage2 && s_axi_wvalid && ~s_axi_bvalid_stage1) begin
                s_axi_bvalid_stage1 <= 1'b1;
                s_axi_bresp_stage1  <= 2'b00; // OKAY
                axi_aw_en_resp_stage1    <= 1'b0;
            end else if (s_axi_bvalid_stage1 && s_axi_bready) begin
                s_axi_bvalid_stage1 <= 1'b0;
                axi_aw_en_resp_stage1    <= 1'b1;
            end
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid_stage2 <= 1'b0;
            s_axi_bresp_stage2  <= 2'b00;
            axi_aw_en_resp_stage2    <= 1'b1;
        end else begin
            s_axi_bvalid_stage2 <= s_axi_bvalid_stage1;
            s_axi_bresp_stage2  <= s_axi_bresp_stage1;
            axi_aw_en_resp_stage2    <= axi_aw_en_resp_stage1;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid_stage3 <= 1'b0;
            s_axi_bresp_stage3  <= 2'b00;
            axi_aw_en_resp_stage3    <= 1'b1;
        end else begin
            s_axi_bvalid_stage3 <= s_axi_bvalid_stage2;
            s_axi_bresp_stage3  <= s_axi_bresp_stage2;
            axi_aw_en_resp_stage3    <= axi_aw_en_resp_stage2;
        end
    end

    assign s_axi_bvalid = s_axi_bvalid_stage3;
    assign s_axi_bresp  = s_axi_bresp_stage3;

    // AXI4-Lite Read FSM Pipeline
    reg arready_stage1_int, arready_stage2_int, arready_stage3_int;
    reg arready_stage1_reg, arready_stage2_reg, arready_stage3_reg;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage1_int <= 1'b0;
        end else begin
            if (~arready_stage1_int && s_axi_arvalid) begin
                arready_stage1_int <= 1'b1;
            end else begin
                arready_stage1_int <= 1'b0;
            end
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage2_int <= 1'b0;
        end else begin
            arready_stage2_int <= arready_stage1_int;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage3_int <= 1'b0;
        end else begin
            arready_stage3_int <= arready_stage2_int;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage1_reg <= 1'b0;
        end else begin
            arready_stage1_reg <= arready_stage3_int;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage2_reg <= 1'b0;
        end else begin
            arready_stage2_reg <= arready_stage1_reg;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            arready_stage3_reg <= 1'b0;
        end else begin
            arready_stage3_reg <= arready_stage2_reg;
        end
    end

    assign s_axi_arready = arready_stage3_reg;

    // Read Data Generation Pipeline
    reg        s_axi_rvalid_stage1, s_axi_rvalid_stage2, s_axi_rvalid_stage3;
    reg [1:0]  s_axi_rresp_stage1, s_axi_rresp_stage2, s_axi_rresp_stage3;
    reg [7:0]  s_axi_rdata_stage1, s_axi_rdata_stage2, s_axi_rdata_stage3;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid_stage1 <= 1'b0;
            s_axi_rresp_stage1  <= 2'b00;
            s_axi_rdata_stage1  <= 8'h00;
        end else begin
            if (arready_stage3_int && s_axi_arvalid && ~s_axi_rvalid_stage1) begin
                // Address decode for read
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    4'h0: s_axi_rdata_stage1 <= random_value_reg_stage2; // Only address 0x0 is valid for random_value
                    default: s_axi_rdata_stage1 <= 8'h00;
                endcase
                s_axi_rresp_stage1 <= 2'b00; // OKAY
                s_axi_rvalid_stage1 <= 1'b1;
            end else if (s_axi_rvalid_stage1 && s_axi_rready) begin
                s_axi_rvalid_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid_stage2 <= 1'b0;
            s_axi_rresp_stage2  <= 2'b00;
            s_axi_rdata_stage2  <= 8'h00;
        end else begin
            s_axi_rvalid_stage2 <= s_axi_rvalid_stage1;
            s_axi_rresp_stage2  <= s_axi_rresp_stage1;
            s_axi_rdata_stage2  <= s_axi_rdata_stage1;
        end
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid_stage3 <= 1'b0;
            s_axi_rresp_stage3  <= 2'b00;
            s_axi_rdata_stage3  <= 8'h00;
        end else begin
            s_axi_rvalid_stage3 <= s_axi_rvalid_stage2;
            s_axi_rresp_stage3  <= s_axi_rresp_stage2;
            s_axi_rdata_stage3  <= s_axi_rdata_stage2;
        end
    end

    assign s_axi_rvalid = s_axi_rvalid_stage3;
    assign s_axi_rresp  = s_axi_rresp_stage3;
    assign s_axi_rdata  = s_axi_rdata_stage3;

endmodule