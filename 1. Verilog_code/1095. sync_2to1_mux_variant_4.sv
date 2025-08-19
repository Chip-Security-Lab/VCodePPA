//SystemVerilog
module axi4lite_2to1_mux #(
    parameter ADDR_WIDTH = 4
)(
    input  wire             clk,            // Clock signal
    input  wire             rst_n,          // Active-low synchronous reset
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
    output reg  [7:0]            s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // AXI4-Lite Address Map
    localparam ADDR_DATA_A     = 4'h0;
    localparam ADDR_DATA_B     = 4'h4;
    localparam ADDR_SEL        = 4'h8;
    localparam ADDR_VALID_IN   = 4'hC;
    localparam ADDR_FLUSH      = 4'h10;
    localparam ADDR_Q_OUT      = 4'h14;
    localparam ADDR_VALID_OUT  = 4'h18;

    // Internal registers for input signals
    reg [7:0] data_a_reg, data_b_reg;
    reg       sel_reg;
    reg       valid_in_reg;
    reg       flush_reg;

    // Internal registers for output signals
    reg [7:0] q_out_reg;
    reg       valid_out_reg;

    // Pipeline registers
    reg [7:0] data_a_stage1, data_b_stage1;
    reg       sel_stage1;
    reg       valid_stage1;
    wire      ready_stage1;

    reg [7:0] mux_out_stage2;
    reg       valid_stage2;

    // AXI4-Lite handshake signals
    reg aw_en;
    reg ar_en;

    // Write FSM
    always @(posedge clk) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
        end else begin
            // Write address handshake
            if (!s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
            end else if (s_axi_awready && s_axi_wready && s_axi_bvalid && s_axi_bready) begin
                s_axi_awready <= 1'b0;
            end else if (s_axi_awready && s_axi_wready) begin
                s_axi_awready <= 1'b0;
            end

            // Write data handshake
            if (!s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else if (s_axi_awready && s_axi_wready) begin
                s_axi_wready <= 1'b0;
            end

            // Write response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // Write enable
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && aw_en) begin
                aw_en <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end
        end
    end

    // Write operation
    always @(posedge clk) begin
        if (!rst_n) begin
            data_a_reg   <= 8'd0;
            data_b_reg   <= 8'd0;
            sel_reg      <= 1'b0;
            valid_in_reg <= 1'b0;
            flush_reg    <= 1'b0;
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            case (s_axi_awaddr)
                ADDR_DATA_A: begin
                    if (s_axi_wstrb[0]) data_a_reg <= s_axi_wdata;
                end
                ADDR_DATA_B: begin
                    if (s_axi_wstrb[0]) data_b_reg <= s_axi_wdata;
                end
                ADDR_SEL: begin
                    if (s_axi_wstrb[0]) sel_reg <= s_axi_wdata[0];
                end
                ADDR_VALID_IN: begin
                    if (s_axi_wstrb[0]) valid_in_reg <= s_axi_wdata[0];
                end
                ADDR_FLUSH: begin
                    if (s_axi_wstrb[0]) flush_reg <= s_axi_wdata[0];
                end
                default: ;
            endcase
        end else if (flush_reg) begin
            flush_reg <= 1'b0;
        end
    end

    // Read FSM
    always @(posedge clk) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            ar_en         <= 1'b1;
        end else begin
            // Read address handshake
            if (!s_axi_arready && s_axi_arvalid && ar_en) begin
                s_axi_arready <= 1'b1;
            end else if (s_axi_arready && s_axi_rvalid && s_axi_rready) begin
                s_axi_arready <= 1'b0;
            end

            // Read valid
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

            // Read enable
            if (s_axi_arready && s_axi_arvalid && ar_en) begin
                ar_en <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                ar_en <= 1'b1;
            end
        end
    end

    // Read operation
    always @(posedge clk) begin
        if (!rst_n) begin
            s_axi_rdata <= 8'd0;
        end else if (s_axi_arready && s_axi_arvalid) begin
            case (s_axi_araddr)
                ADDR_DATA_A:    s_axi_rdata <= data_a_reg;
                ADDR_DATA_B:    s_axi_rdata <= data_b_reg;
                ADDR_SEL:       s_axi_rdata <= {7'd0, sel_reg};
                ADDR_VALID_IN:  s_axi_rdata <= {7'd0, valid_in_reg};
                ADDR_FLUSH:     s_axi_rdata <= {7'd0, flush_reg};
                ADDR_Q_OUT:     s_axi_rdata <= q_out_reg;
                ADDR_VALID_OUT: s_axi_rdata <= {7'd0, valid_out_reg};
                default:        s_axi_rdata <= 8'd0;
            endcase
        end
    end

    // Core pipeline logic
    assign ready_stage1 = 1'b1;

    always @(posedge clk) begin
        if (!rst_n) begin
            data_a_stage1 <= 8'd0;
            data_b_stage1 <= 8'd0;
            sel_stage1    <= 1'b0;
            valid_stage1  <= 1'b0;
        end else if (flush_reg) begin
            valid_stage1  <= 1'b0;
        end else if (ready_stage1) begin
            data_a_stage1 <= data_a_reg;
            data_b_stage1 <= data_b_reg;
            sel_stage1    <= sel_reg;
            valid_stage1  <= valid_in_reg;
        end
    end

    // 补码加法实现减法运算单元
    wire [7:0] subtrahend_complement;
    wire [7:0] adder_operand_b;
    wire [8:0] adder_result;
    assign subtrahend_complement = ~data_b_stage1 + 8'd1;
    assign adder_operand_b = sel_stage1 ? subtrahend_complement : 8'd0;
    assign adder_result = {1'b0, data_a_stage1} + {1'b0, adder_operand_b};

    // 替换原有mux_out_stage2赋值逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            mux_out_stage2 <= 8'd0;
            valid_stage2   <= 1'b0;
        end else if (flush_reg) begin
            valid_stage2   <= 1'b0;
        end else if (ready_stage1) begin
            if (sel_stage1) begin
                mux_out_stage2 <= adder_result[7:0];
            end else begin
                mux_out_stage2 <= data_a_stage1;
            end
            valid_stage2   <= valid_stage1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            q_out_reg     <= 8'd0;
            valid_out_reg <= 1'b0;
        end else if (flush_reg) begin
            valid_out_reg <= 1'b0;
        end else if (ready_stage1) begin
            q_out_reg     <= mux_out_stage2;
            valid_out_reg <= valid_stage2;
        end
    end

endmodule