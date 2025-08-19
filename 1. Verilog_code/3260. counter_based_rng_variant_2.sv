//SystemVerilog
module counter_based_rng_axi4lite #(
    parameter ADDR_WIDTH = 4,    // 16B address space, can be adjusted
    parameter DATA_WIDTH = 16    // 16-bit data width
)(
    input  wire                  clk,
    input  wire                  reset,

    // AXI4-Lite slave interface
    // Write address channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // Write data channel
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // Write response channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // Read data channel
    output reg [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg [1:0]             s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // Register mapping
    // 0x0: Seed [7:0] + Start [0]
    // 0x4: Random Output [15:0]
    // 0x8: Valid Output [0]
    localparam REG_SEED_ADDR  = 4'h0;
    localparam REG_RAND_ADDR  = 4'h4;
    localparam REG_VALID_ADDR = 4'h8;

    // Internal registers
    reg [7:0]  seed_reg;
    reg        start_reg;
    reg        start_pulse;
    reg        start_req;
    wire       start_ack;

    // Internal RNG pipeline signals (from original module)
    reg [15:0] rand_out;
    reg        valid_out;

    // AXI4-Lite handshake logic
    reg aw_hs, w_hs, ar_hs;
    wire write_en, read_en;

    // Write handshake
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_hs         <= 1'b0;
            w_hs          <= 1'b0;
        end else begin
            // AWREADY
            if (~s_axi_awready && s_axi_awvalid && ~aw_hs)
                s_axi_awready <= 1'b1;
            else
                s_axi_awready <= 1'b0;

            // WREADY
            if (~s_axi_wready && s_axi_wvalid && ~w_hs)
                s_axi_wready <= 1'b1;
            else
                s_axi_wready <= 1'b0;

            // Handshake detection
            aw_hs <= s_axi_awready && s_axi_awvalid;
            w_hs  <= s_axi_wready  && s_axi_wvalid;
        end
    end

    assign write_en = (s_axi_awready && s_axi_awvalid) && (s_axi_wready && s_axi_wvalid);

    // Write response logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
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

    // Read handshake
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axi_arready <= 1'b0;
            ar_hs         <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid && ~ar_hs)
                s_axi_arready <= 1'b1;
            else
                s_axi_arready <= 1'b0;

            ar_hs <= s_axi_arready && s_axi_arvalid;
        end
    end

    assign read_en = s_axi_arready && s_axi_arvalid;

    // Read data logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
        end else begin
            if (read_en) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[ADDR_WIDTH-1:2])
                    REG_SEED_ADDR[ADDR_WIDTH-1:2]:  s_axi_rdata <= {7'b0, start_reg, seed_reg}; // [8:1] reserved, [0] start, [7:0] seed
                    REG_RAND_ADDR[ADDR_WIDTH-1:2]:  s_axi_rdata <= rand_out;
                    REG_VALID_ADDR[ADDR_WIDTH-1:2]: s_axi_rdata <= {15'b0, valid_out};
                    default:                        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write to registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seed_reg  <= 8'd0;
            start_reg <= 1'b0;
            start_req <= 1'b0;
        end else begin
            if (write_en) begin
                case (s_axi_awaddr[ADDR_WIDTH-1:2])
                    REG_SEED_ADDR[ADDR_WIDTH-1:2]: begin
                        if (s_axi_wstrb[0]) begin
                            seed_reg  <= s_axi_wdata[7:0];
                            start_reg <= s_axi_wdata[8];
                            start_req <= s_axi_wdata[8];
                        end
                    end
                    default: ;
                endcase
            end
            // Clear start_req when acknowledged by pipeline
            if (start_ack)
                start_req <= 1'b0;
        end
    end

    // Generate a single-cycle start pulse when start_req is set
    reg start_req_r;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_req_r <= 1'b0;
        end else begin
            start_req_r <= start_req;
        end
    end
    assign start_pulse = start_req & ~start_req_r;

    // RNG pipeline (core logic, unmodified except for input/output adaptation)
    // Stage 1: Counter update
    reg [7:0]  counter_stage1;
    reg [15:0] rand_stage1;
    reg        valid_stage1;
    reg [7:0]  seed_stage1;
    reg        start_stage1;

    // Stage 2: Random calculation
    reg [7:0]  counter_stage2;
    reg [15:0] rand_stage2;
    reg        valid_stage2;
    reg [7:0]  rand_xor_stage2;
    reg [7:0]  rand_add_stage2;
    reg        start_stage2;

    // Stage 3: Output register
    reg [15:0] rand_stage3;
    reg        valid_stage3;
    reg        start_stage3;

    wire flush = reset;

    // Stage 1: Counter update and seed capture
    always @(posedge clk) begin
        if (flush) begin
            counter_stage1 <= seed_reg;
            rand_stage1    <= {seed_reg, ~seed_reg};
            valid_stage1   <= 1'b0;
            seed_stage1    <= seed_reg;
            start_stage1   <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage1 + 8'h53;
            rand_stage1    <= rand_stage3;
            valid_stage1   <= valid_stage3 | start_pulse;
            seed_stage1    <= seed_reg;
            start_stage1   <= start_pulse;
        end
    end

    // Stage 2: Random calculation
    always @(posedge clk) begin
        if (flush) begin
            counter_stage2    <= 8'd0;
            rand_stage2       <= 16'd0;
            rand_xor_stage2   <= 8'd0;
            rand_add_stage2   <= 8'd0;
            valid_stage2      <= 1'b0;
            start_stage2      <= 1'b0;
        end else begin
            counter_stage2    <= counter_stage1;
            rand_stage2       <= rand_stage1;
            rand_xor_stage2   <= rand_stage1[7:0] ^ counter_stage1;
            rand_add_stage2   <= rand_stage1[15:8] + counter_stage1;
            valid_stage2      <= valid_stage1;
            start_stage2      <= start_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk) begin
        if (flush) begin
            rand_stage3   <= {seed_reg, ~seed_reg};
            valid_stage3  <= 1'b0;
            start_stage3  <= 1'b0;
        end else if (start_stage2 | valid_stage2) begin
            rand_stage3   <= {rand_xor_stage2, rand_add_stage2};
            valid_stage3  <= valid_stage2;
            start_stage3  <= start_stage2;
        end
    end

    // Output logic
    always @(posedge clk) begin
        if (flush) begin
            rand_out   <= {seed_reg, ~seed_reg};
            valid_out  <= 1'b0;
        end else begin
            rand_out   <= rand_stage3;
            valid_out  <= valid_stage3;
        end
    end

    // Start acknowledge: single cycle when start_pulse is accepted by pipeline (stage 1)
    assign start_ack = start_pulse;

endmodule