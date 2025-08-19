//SystemVerilog
module sync_arith_right_shifter_axi4lite #(
    parameter integer ADDR_WIDTH = 4,
    parameter integer DATA_WIDTH = 8
)(
    input  wire                   axi_aclk,
    input  wire                   axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    // Internal registers
    reg [DATA_WIDTH-1:0] reg_data_in;
    reg [2:0]            reg_shift_by;
    reg [DATA_WIDTH-1:0] reg_result_d;
    reg [DATA_WIDTH-1:0] reg_result_q;

    // Write state machine
    reg                  axi_awready_r;
    reg                  axi_wready_r;
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_en;

    // Read state machine
    reg                  axi_arready_r;
    reg [ADDR_WIDTH-1:0] araddr_latched;

    // Read data pipeline registers
    reg [DATA_WIDTH-1:0] rdata_pipe;
    reg [1:0]            rresp_pipe;
    reg                  rvalid_pipe;

    // Write strobes (not used for 8-bit, but for completeness)
    wire                 wstrb0 = s_axi_wstrb[0];

    // AXI4-Lite address mapping
    localparam ADDR_DATA_IN   = 4'h0;
    localparam ADDR_SHIFT_BY  = 4'h4;
    localparam ADDR_RESULT    = 4'h8;

    // Write address handshake
    assign s_axi_awready = axi_awready_r;
    assign s_axi_wready  = axi_wready_r;

    // Read address handshake
    assign s_axi_arready = axi_arready_r;

    // Write address and data handshake
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_awready_r <= 1'b1;
            axi_wready_r  <= 1'b1;
            aw_en         <= 1'b1;
        end else begin
            if (s_axi_awvalid && s_axi_awready && aw_en) begin
                awaddr_latched <= s_axi_awaddr;
                axi_awready_r  <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                axi_awready_r  <= 1'b1;
            end

            if (s_axi_wvalid && s_axi_wready && aw_en) begin
                axi_wready_r <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                axi_wready_r <= 1'b1;
            end

            if ((s_axi_awvalid && s_axi_awready && aw_en) &&
                (s_axi_wvalid && s_axi_wready && aw_en)) begin
                aw_en <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end
        end
    end

    // Write register logic
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            reg_data_in  <= {DATA_WIDTH{1'b0}};
            reg_shift_by <= 3'b0;
        end else if (s_axi_wvalid && s_axi_wready && s_axi_awvalid && s_axi_awready) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:0])
                ADDR_DATA_IN: begin
                    if (wstrb0) reg_data_in <= s_axi_wdata;
                end
                ADDR_SHIFT_BY: begin
                    if (wstrb0) reg_shift_by <= s_axi_wdata[2:0];
                end
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (!s_axi_bvalid && (s_axi_wvalid && s_axi_wready && s_axi_awvalid && s_axi_awready)) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address latch
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_arready_r  <= 1'b1;
            araddr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (s_axi_arvalid && axi_arready_r) begin
                araddr_latched <= s_axi_araddr;
                axi_arready_r  <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                axi_arready_r  <= 1'b1;
            end
        end
    end

    // Arithmetic right shift operation (move register before output register)
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            reg_result_d <= {DATA_WIDTH{1'b0}};
        end else begin
            reg_result_d <= $signed(reg_data_in) >>> reg_shift_by;
        end
    end

    // Pipeline register for reg_result
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            reg_result_q <= {DATA_WIDTH{1'b0}};
        end else begin
            reg_result_q <= reg_result_d;
        end
    end

    // Read data pipeline for output registers (move output register to pipeline before output)
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            rdata_pipe <= {DATA_WIDTH{1'b0}};
            rresp_pipe <= 2'b00;
            rvalid_pipe <= 1'b0;
        end else begin
            if (!rvalid_pipe && s_axi_arvalid && axi_arready_r) begin
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    ADDR_DATA_IN:   rdata_pipe <= reg_data_in;
                    ADDR_SHIFT_BY:  rdata_pipe <= {5'b0, reg_shift_by};
                    ADDR_RESULT:    rdata_pipe <= reg_result_q;
                    default:        rdata_pipe <= {DATA_WIDTH{1'b0}};
                endcase
                rresp_pipe <= 2'b00; // OKAY
                rvalid_pipe <= 1'b1;
            end else if (rvalid_pipe && s_axi_rready) begin
                rvalid_pipe <= 1'b0;
            end
        end
    end

    // Output registers for AXI read data (moved register from output to before output assignment)
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            s_axi_rvalid <= rvalid_pipe;
            s_axi_rresp  <= rresp_pipe;
            s_axi_rdata  <= rdata_pipe;
        end
    end

endmodule