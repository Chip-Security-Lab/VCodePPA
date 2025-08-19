//SystemVerilog
module rng_galois_lfsr_2_pipeline_axi4lite #(
    parameter ADDR_WIDTH = 4 // Enough for simple registers
) (
    input                   clk,
    input                   rst_n,

    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,
    // Write Data Channel
    input  [31:0]           s_axi_wdata,
    input  [3:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output                  s_axi_wready,
    // Write Response Channel
    output [1:0]            s_axi_bresp,
    output                  s_axi_bvalid,
    input                   s_axi_bready,
    // Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output                  s_axi_arready,
    // Read Data Channel
    output [31:0]           s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // AXI4-Lite internal registers
    localparam REG_LFSR_DATA      = 4'h0;
    localparam REG_LFSR_VALID     = 4'h4;
    localparam REG_LFSR_CONTROL   = 4'h8;

    reg        enable_reg;
    wire       enable;

    assign enable = enable_reg;

    // LFSR pipeline signals
    reg [15:0] state_stage1, state_stage3;
    reg [15:0] next_state_stage2;
    reg        valid_stage1, valid_stage2, valid_stage3;

    // AXI4-Lite handshake signals
    reg        awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg [1:0]  bresp_reg, rresp_reg;
    reg [31:0] rdata_reg;

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg;
    assign s_axi_rresp   = rresp_reg;
    assign s_axi_rdata   = rdata_reg;

    // Write address and data latching
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg                  awaddr_latched, wdata_latched;
    reg [31:0]           wdata_reg;
    reg [3:0]            wstrb_reg;

    // Write address channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg      <= 1'b1;
            awaddr_reg       <= {ADDR_WIDTH{1'b0}};
            awaddr_latched   <= 1'b0;
        end else if (s_axi_awvalid && awready_reg) begin
            awaddr_reg       <= s_axi_awaddr;
            awready_reg      <= 1'b0;
            awaddr_latched   <= 1'b1;
        end else if (bvalid_reg && s_axi_bready) begin
            awready_reg      <= 1'b1;
            awaddr_latched   <= 1'b0;
        end
    end

    // Write data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_reg     <= 1'b1;
            wdata_reg      <= 32'b0;
            wstrb_reg      <= 4'b0;
            wdata_latched  <= 1'b0;
        end else if (s_axi_wvalid && wready_reg) begin
            wdata_reg     <= s_axi_wdata;
            wstrb_reg     <= s_axi_wstrb;
            wready_reg    <= 1'b0;
            wdata_latched <= 1'b1;
        end else if (bvalid_reg && s_axi_bready) begin
            wready_reg    <= 1'b1;
            wdata_latched <= 1'b0;
        end
    end

    // Write response logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else if (awaddr_latched && wdata_latched && !bvalid_reg) begin
            bvalid_reg <= 1'b1;
            bresp_reg  <= 2'b00; // OKAY
        end else if (bvalid_reg && s_axi_bready) begin
            bvalid_reg <= 1'b0;
        end
    end

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= 1'b0;
        end else if (awaddr_latched && wdata_latched && !bvalid_reg) begin
            case (awaddr_reg)
                REG_LFSR_CONTROL: begin
                    if (wstrb_reg[0]) enable_reg <= wdata_reg[0];
                end
                default: ;
            endcase
        end
    end

    // Read address channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b1;
        end else if (s_axi_arvalid && arready_reg) begin
            arready_reg <= 1'b0;
        end else if (rvalid_reg && s_axi_rready) begin
            arready_reg <= 1'b1;
        end
    end

    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 32'b0;
            rresp_reg  <= 2'b00;
        end else if (s_axi_arvalid && arready_reg) begin
            rvalid_reg <= 1'b1;
            case (s_axi_araddr)
                REG_LFSR_DATA: begin
                    rdata_reg <= {16'b0, state_stage3};
                end
                REG_LFSR_VALID: begin
                    rdata_reg <= {31'b0, valid_stage3};
                end
                REG_LFSR_CONTROL: begin
                    rdata_reg <= {31'b0, enable_reg};
                end
                default: begin
                    rdata_reg <= 32'b0;
                end
            endcase
            rresp_reg <= 2'b00; // OKAY
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end

    // LFSR Pipeline Logic

    // Stage 1: Capture current state, prepare for feedback calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1  <= 16'hACE1;
            valid_stage1  <= 1'b0;
        end else if (enable) begin
            state_stage1  <= state_stage1; // Hold current state for pipeline
            valid_stage1  <= 1'b1;
        end else begin
            valid_stage1  <= 1'b0;
        end
    end

    // Stage 2: Calculate feedback bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_stage2 <= 16'hACE1;
            valid_stage2      <= 1'b0;
        end else if (valid_stage1) begin
            next_state_stage2[0]      <= state_stage1[15];
            next_state_stage2[1]      <= state_stage1[0]  ^ state_stage1[15];
            next_state_stage2[2]      <= state_stage1[1];
            next_state_stage2[3]      <= state_stage1[2]  ^ state_stage1[15];
            next_state_stage2[15:4]   <= state_stage1[14:3];
            valid_stage2              <= 1'b1;
        end else begin
            valid_stage2              <= 1'b0;
        end
    end

    // Stage 3: Register final output state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= 16'hACE1;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            state_stage3 <= next_state_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Pipeline state update for next cycle (feedback)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= 16'hACE1;
        end else if (enable && valid_stage3) begin
            state_stage1 <= state_stage3;
        end
    end

endmodule