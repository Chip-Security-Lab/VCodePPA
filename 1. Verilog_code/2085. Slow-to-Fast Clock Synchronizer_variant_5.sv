//SystemVerilog
// Top-level module: Hierarchical slow-to-fast clock domain synchronizer (Pipelined) with AXI4-Lite interface
module slow_to_fast_sync_axi4lite #(
    parameter WIDTH = 12,
    parameter ADDR_WIDTH = 4   // Enough to map a few registers
)(
    input  wire                     s_axi_aclk,
    input  wire                     s_axi_aresetn,
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  wire [WIDTH-1:0]         s_axi_wdata,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg [1:0]                s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg [WIDTH-1:0]          s_axi_rdata,
    output reg [1:0]                s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,
    // Clock Domain Signals
    input  wire                     slow_clk,
    input  wire                     fast_clk
);

    // Internal reset signals
    wire axi_rst_n = s_axi_aresetn;

    // Register Map
    localparam ADDR_SLOW_DATA     = 4'h0; // Write: slow domain data input
    localparam ADDR_FAST_DATA     = 4'h4; // Read: fast domain data output
    localparam ADDR_DATA_VALID    = 4'h8; // Read: data_valid flag

    // Internal registers for AXI to slow domain interface
    reg [WIDTH-1:0] slow_data_reg;
    reg             slow_data_wr_stb;

    // AXI4-Lite write state machine
    reg aw_hs, w_hs;
    wire write_en = aw_hs & w_hs;

    // Write address handshake
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            s_axi_awready <= 1'b0;
        end else if (!s_axi_awready && s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
        end else begin
            s_axi_awready <= 1'b0;
        end
    end

    // Write data handshake
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            s_axi_wready <= 1'b0;
        end else if (!s_axi_wready && s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
        end else begin
            s_axi_wready <= 1'b0;
        end
    end

    // Write handshake
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            aw_hs <= 1'b0;
            w_hs  <= 1'b0;
        end else begin
            aw_hs <= s_axi_awready & s_axi_awvalid;
            w_hs  <= s_axi_wready  & s_axi_wvalid;
        end
    end

    // Write operation and bus response
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            slow_data_reg <= {WIDTH{1'b0}};
            slow_data_wr_stb <= 1'b0;
        end else begin
            s_axi_bvalid <= 1'b0;
            slow_data_wr_stb <= 1'b0;
            if (write_en) begin
                case (s_axi_awaddr)
                    ADDR_SLOW_DATA: begin
                        slow_data_reg <= s_axi_wdata;
                        slow_data_wr_stb <= 1'b1;
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY response
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite read state machine
    reg ar_hs;
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            s_axi_arready <= 1'b0;
        end else if (!s_axi_arready && s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
        end else begin
            s_axi_arready <= 1'b0;
        end
    end

    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            ar_hs <= 1'b0;
        end else begin
            ar_hs <= s_axi_arready & s_axi_arvalid;
        end
    end

    // Data from fast domain
    wire [WIDTH-1:0] fast_data_sync;
    wire             data_valid_sync;

    // Read operation and bus response
    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {WIDTH{1'b0}};
        end else begin
            s_axi_rvalid <= 1'b0;
            if (ar_hs) begin
                case (s_axi_araddr)
                    ADDR_FAST_DATA: begin
                        s_axi_rdata <= fast_data_sync;
                    end
                    ADDR_DATA_VALID: begin
                        s_axi_rdata <= {{(WIDTH-1){1'b0}}, data_valid_sync};
                    end
                    default: begin
                        s_axi_rdata <= {WIDTH{1'b0}};
                    end
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY response
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Slow-to-fast clock domain synchronizer instance
    // The slow_data input and its strobe are synchronized to slow_clk
    reg [WIDTH-1:0] slow_data_sync;
    reg             slow_data_stb_sync;
    reg [1:0]       slow_data_stb_sync_ff;
    wire            slow_data_wr_pulse;

    // Synchronize write strobe to slow_clk domain
    always @(posedge slow_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            slow_data_sync <= {WIDTH{1'b0}};
            slow_data_stb_sync_ff <= 2'b00;
            slow_data_stb_sync <= 1'b0;
        end else begin
            slow_data_stb_sync_ff <= {slow_data_stb_sync_ff[0], slow_data_wr_stb};
            if (slow_data_stb_sync_ff[1] & ~slow_data_stb_sync_ff[0]) begin
                slow_data_sync <= slow_data_reg;
                slow_data_stb_sync <= 1'b1;
            end else begin
                slow_data_stb_sync <= 1'b0;
            end
        end
    end
    assign slow_data_wr_pulse = slow_data_stb_sync;

    // Internal signals for the synchronizer core
    wire [WIDTH-1:0] fast_data_int;
    wire             data_valid_int;

    // Instantiate the core synchronizer
    slow_to_fast_sync_core #(
        .WIDTH(WIDTH)
    ) u_slow_to_fast_sync_core (
        .slow_clk      (slow_clk),
        .fast_clk      (fast_clk),
        .rst_n         (axi_rst_n),
        .slow_data     (slow_data_sync),
        .slow_data_wr  (slow_data_wr_pulse),
        .fast_data     (fast_data_int),
        .data_valid    (data_valid_int)
    );

    // Synchronize fast_data and data_valid to AXI clock domain
    reg [WIDTH-1:0] fast_data_axi_ff1, fast_data_axi_ff2;
    reg             data_valid_axi_ff1, data_valid_axi_ff2;

    always @(posedge s_axi_aclk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            fast_data_axi_ff1 <= {WIDTH{1'b0}};
            fast_data_axi_ff2 <= {WIDTH{1'b0}};
            data_valid_axi_ff1 <= 1'b0;
            data_valid_axi_ff2 <= 1'b0;
        end else begin
            fast_data_axi_ff1 <= fast_data_int;
            fast_data_axi_ff2 <= fast_data_axi_ff1;
            data_valid_axi_ff1 <= data_valid_int;
            data_valid_axi_ff2 <= data_valid_axi_ff1;
        end
    end

    assign fast_data_sync = fast_data_axi_ff2;
    assign data_valid_sync = data_valid_axi_ff2;

endmodule

//------------------------------------------------------------------------------
// Core slow-to-fast synchronizer with explicit data strobe
//------------------------------------------------------------------------------
module slow_to_fast_sync_core #(parameter WIDTH = 12) (
    input  wire                  slow_clk,
    input  wire                  fast_clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      slow_data,
    input  wire                  slow_data_wr,
    output wire [WIDTH-1:0]      fast_data,
    output wire                  data_valid
);

    // Internal signals for inter-module connectivity
    wire                         slow_toggle_stage1;
    wire [WIDTH-1:0]             captured_data_stage1;
    wire                         slow_toggle_stage2;
    wire [WIDTH-1:0]             captured_data_stage2;

    wire [2:0]                   fast_sync_stage1;
    wire [2:0]                   fast_sync_stage2;

    wire                         fast_toggle_prev_stage1;
    wire                         fast_toggle_prev_stage2;

    // Slow domain controller: generates toggle and captures data (Stage 1)
    slow_domain_ctrl #(
        .WIDTH(WIDTH)
    ) u_slow_domain_ctrl (
        .clk            (slow_clk),
        .rst_n          (rst_n),
        .in_data        (slow_data),
        .data_wr        (slow_data_wr),
        .toggle_out     (slow_toggle_stage1),
        .captured_data  (captured_data_stage1)
    );

    // Pipeline register between Stage 1 and Stage 2 in slow_clk domain
    reg slow_toggle_stage2_r;
    reg [WIDTH-1:0] captured_data_stage2_r;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle_stage2_r    <= 1'b0;
            captured_data_stage2_r  <= {WIDTH{1'b0}};
        end else begin
            slow_toggle_stage2_r    <= slow_toggle_stage1;
            captured_data_stage2_r  <= captured_data_stage1;
        end
    end
    assign slow_toggle_stage2   = slow_toggle_stage2_r;
    assign captured_data_stage2 = captured_data_stage2_r;

    // Fast domain synchronizer: synchronizes toggle across clock domains (Stage 2)
    toggle_synchronizer u_toggle_synchronizer (
        .clk            (fast_clk),
        .rst_n          (rst_n),
        .async_toggle   (slow_toggle_stage2),
        .sync_toggle    (fast_sync_stage1)
    );

    // Pipeline register between Stage 2 and Stage 3 in fast_clk domain
    reg [2:0] fast_sync_stage2_r;
    reg [WIDTH-1:0] captured_data_fast_stage2_r;
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_sync_stage2_r         <= 3'b0;
            captured_data_fast_stage2_r<= {WIDTH{1'b0}};
        end else begin
            fast_sync_stage2_r         <= fast_sync_stage1;
            captured_data_fast_stage2_r<= captured_data_stage2;
        end
    end
    assign fast_sync_stage2     = fast_sync_stage2_r;

    // Fast toggle previous pipeline
    reg fast_toggle_prev_stage1_r;
    reg fast_toggle_prev_stage2_r;
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_toggle_prev_stage1_r <= 1'b0;
            fast_toggle_prev_stage2_r <= 1'b0;
        end else begin
            fast_toggle_prev_stage1_r <= fast_sync_stage2[2];
            fast_toggle_prev_stage2_r <= fast_toggle_prev_stage1_r;
        end
    end
    assign fast_toggle_prev_stage1 = fast_toggle_prev_stage1_r;
    assign fast_toggle_prev_stage2 = fast_toggle_prev_stage2_r;

    // Fast domain data latch and valid generator (Stage 3)
    reg [WIDTH-1:0] data_stage3_r;
    reg data_valid_stage3_r;
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3_r      <= {WIDTH{1'b0}};
            data_valid_stage3_r<= 1'b0;
        end else begin
            if (fast_sync_stage2[2] != fast_toggle_prev_stage2) begin
                data_stage3_r      <= captured_data_fast_stage2_r;
                data_valid_stage3_r<= 1'b1;
            end else begin
                data_valid_stage3_r<= 1'b0;
            end
        end
    end

    // Pipeline register for output (Stage 4)
    reg [WIDTH-1:0] data_stage4_r;
    reg data_valid_stage4_r;
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage4_r      <= {WIDTH{1'b0}};
            data_valid_stage4_r<= 1'b0;
        end else begin
            data_stage4_r      <= data_stage3_r;
            data_valid_stage4_r<= data_valid_stage3_r;
        end
    end

    assign fast_data  = data_stage4_r;
    assign data_valid = data_valid_stage4_r;

endmodule

//------------------------------------------------------------------------------
// Slow domain controller: captures input data and generates toggle signal (Pipelined)
// Modified to support data write strobe
//------------------------------------------------------------------------------
module slow_domain_ctrl #(parameter WIDTH = 12) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] in_data,
    input  wire             data_wr,
    output reg              toggle_out,
    output reg [WIDTH-1:0]  captured_data
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_out    <= 1'b0;
            captured_data <= {WIDTH{1'b0}};
        end else if (data_wr) begin
            toggle_out    <= ~toggle_out;
            captured_data <= in_data;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Toggle synchronizer: multi-stage synchronizer for CDC (Pipelined)
//------------------------------------------------------------------------------
module toggle_synchronizer (
    input  wire clk,
    input  wire rst_n,
    input  wire async_toggle,
    output reg [2:0] sync_toggle
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_toggle <= 3'b0;
        end else begin
            sync_toggle <= {sync_toggle[1:0], async_toggle};
        end
    end
endmodule