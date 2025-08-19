//SystemVerilog
module rng_combine_14_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                clk,
    input                rst,

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

    // AXI4-Lite internal registers and signals
    reg [7:0]  rnd_reg;
    reg        en_reg;

    // AXI4-Lite handshake signals
    reg        awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg [1:0]  bresp_reg, rresp_reg;
    reg [7:0]  rdata_reg;

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = rresp_reg;
    assign s_axi_rvalid  = rvalid_reg;

    // Address Map
    localparam ADDR_RND   = 4'h0; // rnd register read
    localparam ADDR_EN    = 4'h4; // enable register write
    localparam ADDR_CTRL  = 4'h8; // control register (reset)
    
    // Write FSM
    reg aw_en;
    always @(posedge clk) begin
        if (rst) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (!awready_reg && s_axi_awvalid && aw_en) begin
                awready_reg <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                awready_reg <= 1'b0;
            end

            if (!wready_reg && s_axi_wvalid && aw_en) begin
                wready_reg <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                wready_reg <= 1'b0;
            end

            if (s_axi_awvalid && s_axi_wvalid && aw_en && !awready_reg && !wready_reg) begin
                aw_en <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end
        end
    end

    // Write operation
    always @(posedge clk) begin
        if (rst) begin
            en_reg <= 1'b0;
        end else if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:0])
                ADDR_EN: begin
                    if (s_axi_wstrb[0]) en_reg <= s_axi_wdata[0];
                end
                ADDR_CTRL: begin
                    if (s_axi_wstrb[0] && s_axi_wdata[0]) en_reg <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge clk) begin
        if (rst) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && s_axi_awvalid && wready_reg && s_axi_wvalid && !bvalid_reg) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge clk) begin
        if (rst) begin
            arready_reg <= 1'b0;
        end else begin
            if (!arready_reg && s_axi_arvalid) begin
                arready_reg <= 1'b1;
            end else if (rvalid_reg && s_axi_rready) begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Read operation and response
    // Pipeline insertion for address decode and data mux
    reg [ADDR_WIDTH-1:0] araddr_pipe;
    reg                  arvalid_pipe;
    always @(posedge clk) begin
        if (rst) begin
            araddr_pipe  <= {ADDR_WIDTH{1'b0}};
            arvalid_pipe <= 1'b0;
        end else begin
            if (arready_reg && s_axi_arvalid && !rvalid_reg) begin
                araddr_pipe  <= s_axi_araddr;
                arvalid_pipe <= 1'b1;
            end else if (arvalid_pipe && !rvalid_reg) begin
                arvalid_pipe <= 1'b0;
            end
        end
    end

    // Pipeline stage for data mux
    reg [7:0] rdata_mux_pipe;
    always @(posedge clk) begin
        if (rst) begin
            rdata_mux_pipe <= 8'd0;
        end else if (arvalid_pipe && !rvalid_reg) begin
            case (araddr_pipe)
                ADDR_RND:   rdata_mux_pipe <= rnd_reg;
                ADDR_EN:    rdata_mux_pipe <= {7'd0, en_reg};
                default:    rdata_mux_pipe <= 8'd0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
            rdata_reg  <= 8'd0;
        end else begin
            if (arvalid_pipe && !rvalid_reg) begin
                rvalid_reg <= 1'b1;
                rresp_reg  <= 2'b00; // OKAY
                rdata_reg  <= rdata_mux_pipe;
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    // RNG core logic
    // Pipeline the XOR/SHIFT logic for critical path reduction
    reg [7:0] rnd_shift_left;
    reg [7:0] rnd_shift_right;
    reg [7:0] rnd_xor_stage1;
    reg [7:0] rnd_xor_stage2;

    always @(posedge clk) begin
        if (rst) begin
            rnd_shift_left  <= 8'd0;
            rnd_shift_right <= 8'd0;
            rnd_xor_stage1  <= 8'd0;
            rnd_xor_stage2  <= 8'd0;
        end else if (en_reg) begin
            rnd_shift_left  <= rnd_reg << 3;
            rnd_shift_right <= rnd_reg >> 2;
            rnd_xor_stage1  <= rnd_shift_left ^ rnd_shift_right;
            rnd_xor_stage2  <= rnd_xor_stage1 ^ 8'h5A;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            rnd_reg <= 8'h99;
        end else if (en_reg) begin
            rnd_reg <= rnd_xor_stage2;
        end
    end

endmodule