//SystemVerilog
module rng_cross_10_axi4lite #(
    parameter AXI_ADDR_WIDTH = 4,   // 16 bytes address space
    parameter AXI_DATA_WIDTH = 32   // AXI4-Lite standard data width
)(
    input                         clk,
    input                         rst,

    // AXI4-Lite Write Address Channel
    input      [AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input                            s_axi_awvalid,
    output reg                       s_axi_awready,

    // AXI4-Lite Write Data Channel
    input      [AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input      [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input                            s_axi_wvalid,
    output reg                       s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]                 s_axi_bresp,
    output reg                       s_axi_bvalid,
    input                            s_axi_bready,

    // AXI4-Lite Read Address Channel
    input      [AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input                            s_axi_arvalid,
    output reg                       s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output reg [1:0]                 s_axi_rresp,
    output reg                       s_axi_rvalid,
    input                            s_axi_rready
);

    // Address Map (offsets)
    localparam ADDR_CTRL         = 4'h0; // bit[0]: enable
    localparam ADDR_STATUS       = 4'h4; // reserved, can be 0
    localparam ADDR_RANDOM       = 4'h8; // output random number [7:0]

    // Control and status registers
    reg        en_reg;
    wire       en;

    assign en = en_reg;

    // RNG State Registers
    reg [7:0] state1_stage1, state2_stage1;
    reg [7:0] state1_stage2, state2_stage2;
    reg [7:0] rnd_stage3;

    // AXI4-Lite handshake state
    reg aw_en;

    // Write address handshake
    always @(posedge clk) begin
        if (rst) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (s_axi_wready && s_axi_wvalid) begin
                s_axi_awready <= 1'b0;
                aw_en <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge clk) begin
        if (rst) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Write response logic
    always @(posedge clk) begin
        if (rst) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Control register write
    always @(posedge clk) begin
        if (rst) begin
            en_reg <= 1'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr[AXI_ADDR_WIDTH-1:0])
                    ADDR_CTRL: begin
                        if (s_axi_wstrb[0]) en_reg <= s_axi_wdata[0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Read address handshake
    always @(posedge clk) begin
        if (rst) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // Read data response
    always @(posedge clk) begin
        if (rst) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                case (s_axi_araddr[AXI_ADDR_WIDTH-1:0])
                    ADDR_CTRL:   s_axi_rdata <= {{(AXI_DATA_WIDTH-1){1'b0}}, en_reg};
                    ADDR_STATUS: s_axi_rdata <= {AXI_DATA_WIDTH{1'b0}};
                    ADDR_RANDOM: s_axi_rdata <= {{(AXI_DATA_WIDTH-8){1'b0}}, rnd_stage3};
                    default:     s_axi_rdata <= {AXI_DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // RNG Core Logic

    // Stage 1: State Initialization and Registration
    always @(posedge clk) begin
        if (rst) begin
            state1_stage1 <= 8'hF0;
            state2_stage1 <= 8'h0F;
        end else if (en) begin
            state1_stage1 <= state1_stage2;
            state2_stage1 <= state2_stage2;
        end
    end

    // Stage 2: Next State Calculation
    always @(posedge clk) begin
        if (rst) begin
            state1_stage2 <= 8'hF0;
            state2_stage2 <= 8'h0F;
        end else if (en) begin
            state1_stage2 <= {state1_stage1[6:0], state2_stage1[7] ^ state1_stage1[0]};
            state2_stage2 <= {state2_stage1[6:0], state1_stage1[7] ^ state2_stage1[0]};
        end
    end

    // Stage 3: Output Calculation
    always @(posedge clk) begin
        if (rst) begin
            rnd_stage3 <= 8'h00;
        end else if (en) begin
            rnd_stage3 <= state1_stage2 ^ state2_stage2;
        end
    end

endmodule