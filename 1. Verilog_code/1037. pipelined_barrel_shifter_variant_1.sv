//SystemVerilog
// Top-level: Hierarchical, modularized pipelined barrel shifter with AXI4-Lite interface

module pipelined_barrel_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input wire                     clk,
    input wire                     rst,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]              s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,

    // AXI4-Lite Read Data Channel
    output wire [DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready
);

    // Internal register interface wires
    wire [DATA_WIDTH-1:0]  reg_data_in;
    wire [4:0]             reg_shift;
    wire [DATA_WIDTH-1:0]  reg_data_out;

    wire                   flush_pipeline;

    // AXI4-Lite register interface
    axi4lite_regif #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi4lite_regif (
        .clk              (clk),
        .rst              (rst),

        .s_axi_awaddr     (s_axi_awaddr),
        .s_axi_awvalid    (s_axi_awvalid),
        .s_axi_awready    (s_axi_awready),

        .s_axi_wdata      (s_axi_wdata),
        .s_axi_wstrb      (s_axi_wstrb),
        .s_axi_wvalid     (s_axi_wvalid),
        .s_axi_wready     (s_axi_wready),

        .s_axi_bresp      (s_axi_bresp),
        .s_axi_bvalid     (s_axi_bvalid),
        .s_axi_bready     (s_axi_bready),

        .s_axi_araddr     (s_axi_araddr),
        .s_axi_arvalid    (s_axi_arvalid),
        .s_axi_arready    (s_axi_arready),

        .s_axi_rdata      (s_axi_rdata),
        .s_axi_rresp      (s_axi_rresp),
        .s_axi_rvalid     (s_axi_rvalid),
        .s_axi_rready     (s_axi_rready),

        .reg_data_in      (reg_data_in),
        .reg_shift        (reg_shift),
        .reg_data_out     (reg_data_out),
        .flush_pipeline   (flush_pipeline)
    );

    // Barrel shifter pipeline core
    barrel_shifter_pipeline #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_barrel_shifter_pipeline (
        .clk              (clk),
        .rst              (rst),
        .data_in          (reg_data_in),
        .shift            (reg_shift),
        .flush            (flush_pipeline),
        .data_out         (reg_data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// AXI4-Lite Register Interface Submodule
// Handles AXI4-Lite protocol and register mapping for data_in, shift, and data_out
// -----------------------------------------------------------------------------
module axi4lite_regif #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                    s_axi_awvalid,
    output reg                     s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]               s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                    s_axi_arvalid,
    output reg                     s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg [1:0]               s_axi_rresp,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready,

    // Register interface to core
    output reg [DATA_WIDTH-1:0]    reg_data_in,
    output reg [4:0]               reg_shift,
    input  wire [DATA_WIDTH-1:0]   reg_data_out,
    output reg                     flush_pipeline
);

    localparam ADDR_DATA_IN  = 4'h0;
    localparam ADDR_SHIFT    = 4'h4;
    localparam ADDR_DATA_OUT = 4'h8;

    // Write FSM states
    localparam WR_IDLE = 2'd0,
               WR_RESP = 2'd1;
    reg [1:0] wr_state;

    // Read FSM states
    localparam RD_IDLE = 2'd0,
               RD_DATA = 2'd1;
    reg [1:0] rd_state;

    // Internal registers
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [4:0]            shift_reg;

    // Write FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state      <= WR_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            data_in_reg   <= {DATA_WIDTH{1'b0}};
            shift_reg     <= 5'b0;
            flush_pipeline<= 1'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    s_axi_bvalid  <= 1'b0;
                    flush_pipeline<= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        wr_state      <= WR_RESP;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        s_axi_bvalid  <= 1'b1;
                        s_axi_bresp   <= 2'b00;
                        // Write logic
                        case (s_axi_awaddr[3:0])
                            ADDR_DATA_IN: begin
                                if (s_axi_wstrb[0]) data_in_reg[7:0]   <= s_axi_wdata[7:0];
                                if (s_axi_wstrb[1]) data_in_reg[15:8]  <= s_axi_wdata[15:8];
                                if (s_axi_wstrb[2]) data_in_reg[23:16] <= s_axi_wdata[23:16];
                                if (s_axi_wstrb[3]) data_in_reg[31:24] <= s_axi_wdata[31:24];
                                flush_pipeline <= 1'b1;
                            end
                            ADDR_SHIFT: begin
                                if (s_axi_wstrb[0]) shift_reg[4:0] <= s_axi_wdata[4:0];
                                flush_pipeline <= 1'b1;
                            end
                            default: flush_pipeline <= 1'b0;
                        endcase
                    end
                end
                WR_RESP: begin
                    flush_pipeline <= 1'b0;
                    if (s_axi_bready) begin
                        wr_state      <= WR_IDLE;
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        s_axi_wready  <= 1'b1;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // Read FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                        s_axi_rvalid  <= 1'b1;
                        s_axi_rresp   <= 2'b00;
                        case (s_axi_araddr[3:0])
                            ADDR_DATA_IN:  s_axi_rdata <= data_in_reg;
                            ADDR_SHIFT:    s_axi_rdata <= {27'b0, shift_reg};
                            ADDR_DATA_OUT: s_axi_rdata <= reg_data_out;
                            default:       s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        endcase
                        rd_state <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid  <= 1'b0;
                        s_axi_arready <= 1'b1;
                        rd_state      <= RD_IDLE;
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // Output register assignments
    always @(*) begin
        reg_data_in = data_in_reg;
        reg_shift   = shift_reg;
    end

endmodule

// -----------------------------------------------------------------------------
// Barrel Shifter Pipeline Submodule
// Implements a 3-stage pipelined barrel shifter
// -----------------------------------------------------------------------------
module barrel_shifter_pipeline #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire [4:0]              shift,
    input  wire                    flush,
    output reg  [DATA_WIDTH-1:0]   data_out
);

    // Pipeline registers and valid signals
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg [4:0]            shift_stage1;
    reg                  valid_stage1;

    reg [DATA_WIDTH-1:0] data_in_stage2;
    reg [4:0]            shift_stage2;
    reg [DATA_WIDTH-1:0] shifter_out_stage2;
    reg                  valid_stage2;

    reg [DATA_WIDTH-1:0] shifter_out_stage3;
    reg [4:0]            shift_stage3;
    reg                  valid_stage3;

    // Pipeline valid chain control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (flush) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end

    // Pipeline data chain control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1     <= {DATA_WIDTH{1'b0}};
            shift_stage1       <= 5'b0;
            data_in_stage2     <= {DATA_WIDTH{1'b0}};
            shift_stage2       <= 5'b0;
            shifter_out_stage2 <= {DATA_WIDTH{1'b0}};
            shifter_out_stage3 <= {DATA_WIDTH{1'b0}};
            shift_stage3       <= 5'b0;
        end else if (flush) begin
            data_in_stage1     <= {DATA_WIDTH{1'b0}};
            shift_stage1       <= 5'b0;
            data_in_stage2     <= {DATA_WIDTH{1'b0}};
            shift_stage2       <= 5'b0;
            shifter_out_stage2 <= {DATA_WIDTH{1'b0}};
            shifter_out_stage3 <= {DATA_WIDTH{1'b0}};
            shift_stage3       <= 5'b0;
        end else begin
            // Stage 1: Capture input
            data_in_stage1   <= data_in;
            shift_stage1     <= shift;

            // Stage 2: Shift by 16 and 8 bits
            data_in_stage2   <= data_in_stage1;
            shift_stage2     <= shift_stage1;
            shifter_out_stage2 <= shift_stage1[4] ? {data_in_stage1[15:0], 16'b0} : data_in_stage1;
            shifter_out_stage2 <= shift_stage1[3] ? {shifter_out_stage2[23:0], 8'b0} : shifter_out_stage2;

            // Stage 3: Final shift by [2:0]
            shifter_out_stage3 <= shift_stage2[2:0] ? (shifter_out_stage2 << shift_stage2[2:0]) : shifter_out_stage2;
            shift_stage3       <= shift_stage2;
        end
    end

    // Output register and flush logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage3) begin
                data_out <= shifter_out_stage3;
            end
        end
    end

endmodule