//SystemVerilog
module glitch_filter_reset_detector_axi4lite #(
    parameter AXI_ADDR_WIDTH = 4,   // 16 bytes address space for simple register map
    parameter AXI_DATA_WIDTH = 32   // AXI4-Lite standard data width
)(
    input  wire                        axi_aclk,
    input  wire                        axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                        s_axi_awvalid,
    output wire                        s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                        s_axi_wvalid,
    output wire                        s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]                  s_axi_bresp,
    output reg                         s_axi_bvalid,
    input  wire                        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                        s_axi_arvalid,
    output wire                        s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]                  s_axi_rresp,
    output reg                         s_axi_rvalid,
    input  wire                        s_axi_rready
);

    // Register address map
    localparam ADDR_RAW_RESET            = 4'h0;
    localparam ADDR_FILTERED_RESET       = 4'h4;

    // Internal registers
    reg               raw_reset_reg;
    wire              raw_reset;
    wire              filtered_reset_int;

    // ================== Fanout Buffer Registers ===================
    // s_axi_awvalid buffer tree (2-stage for high fanout)
    reg s_axi_awvalid_buf1;
    reg s_axi_awvalid_buf2;

    // shift_reg_stage1 buffer
    reg [7:0] shift_reg_stage1_buf;

    // reset_detected_stage4 buffer
    reg reset_detected_stage4_buf;

    // axi_awready_reg buffer
    reg axi_awready_reg_buf;

    // axi_wready_reg buffer
    reg axi_wready_reg_buf;

    // Core glitch filter registers
    reg [7:0]         shift_reg_stage1;
    reg [3:0]         popcount_low_stage2;
    reg [3:0]         popcount_high_stage2;
    reg [4:0]         total_popcount_stage3;
    reg               reset_detected_stage4;
    reg               filtered_reset_stage5;
    reg [1:0]         shift_reg_top2_stage5;

    // AXI4-Lite handshake signals
    reg               axi_awready_reg;
    reg               axi_wready_reg;
    reg               axi_arready_reg;

    reg [AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
    reg [AXI_ADDR_WIDTH-1:0] axi_araddr_reg;

    // Assign handshake outputs
    assign s_axi_awready = axi_awready_reg_buf;
    assign s_axi_wready  = axi_wready_reg_buf;
    assign s_axi_arready = axi_arready_reg;

    // RAW_RESET is written from AXI
    assign raw_reset = raw_reset_reg;
    assign filtered_reset_int = filtered_reset_stage5;

    // ================== Fanout Buffer Logic ===================
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_awvalid_buf1 <= 1'b0;
            s_axi_awvalid_buf2 <= 1'b0;
        end else begin
            s_axi_awvalid_buf1 <= s_axi_awvalid;
            s_axi_awvalid_buf2 <= s_axi_awvalid_buf1;
        end
    end

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            shift_reg_stage1_buf <= 8'h00;
        end else begin
            shift_reg_stage1_buf <= shift_reg_stage1;
        end
    end

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            reset_detected_stage4_buf <= 1'b0;
        end else begin
            reset_detected_stage4_buf <= reset_detected_stage4;
        end
    end

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_awready_reg_buf <= 1'b0;
        end else begin
            axi_awready_reg_buf <= axi_awready_reg;
        end
    end

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_wready_reg_buf <= 1'b0;
        end else begin
            axi_wready_reg_buf <= axi_wready_reg;
        end
    end

    // AXI4-Lite Write Address Channel
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_awready_reg <= 1'b0;
            axi_awaddr_reg  <= {AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (!axi_awready_reg && s_axi_awvalid_buf2 && s_axi_wvalid) begin
                axi_awready_reg <= 1'b1;
                axi_awaddr_reg  <= s_axi_awaddr;
            end else begin
                axi_awready_reg <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Data Channel
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_wready_reg <= 1'b0;
        end else begin
            if (!axi_wready_reg && s_axi_wvalid && s_axi_awvalid_buf2) begin
                axi_wready_reg <= 1'b1;
            end else begin
                axi_wready_reg <= 1'b0;
            end
        end
    end

    // Write logic (only raw_reset can be written)
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            raw_reset_reg <= 1'b0;
        end else if (axi_awready_reg_buf && s_axi_awvalid_buf2 && axi_wready_reg_buf && s_axi_wvalid) begin
            if (axi_awaddr_reg[3:0] == ADDR_RAW_RESET) begin
                raw_reset_reg <= s_axi_wdata[0];
            end
        end
    end

    // AXI4-Lite write response
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (axi_awready_reg_buf && s_axi_awvalid_buf2 && axi_wready_reg_buf && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address Channel
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_arready_reg <= 1'b0;
            axi_araddr_reg  <= {AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (!axi_arready_reg && s_axi_arvalid) begin
                axi_arready_reg <= 1'b1;
                axi_araddr_reg  <= s_axi_araddr;
            end else begin
                axi_arready_reg <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Data Channel
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (axi_arready_reg && s_axi_arvalid && !s_axi_rvalid) begin
                case (axi_araddr_reg[3:0])
                    ADDR_RAW_RESET: begin
                        s_axi_rdata <= {{(AXI_DATA_WIDTH-1){1'b0}}, raw_reset_reg};
                        s_axi_rresp <= 2'b00;
                    end
                    ADDR_FILTERED_RESET: begin
                        s_axi_rdata <= {{(AXI_DATA_WIDTH-1){1'b0}}, filtered_reset_int};
                        s_axi_rresp <= 2'b00;
                    end
                    default: begin
                        s_axi_rdata <= {AXI_DATA_WIDTH{1'b0}};
                        s_axi_rresp <= 2'b10; // SLVERR
                    end
                endcase
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // ==================== Core Glitch Filter FSM ====================
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            shift_reg_stage1        <= 8'h00;
            popcount_low_stage2     <= 4'd0;
            popcount_high_stage2    <= 4'd0;
            total_popcount_stage3   <= 5'd0;
            reset_detected_stage4   <= 1'b0;
            filtered_reset_stage5   <= 1'b0;
            shift_reg_top2_stage5   <= 2'b00;
        end else begin
            // Stage 1: Shift register
            shift_reg_stage1 <= {shift_reg_stage1[6:0], raw_reset};

            // Stage 2: Partial popcount (split 8 bits into two 4-bit chunks)
            popcount_low_stage2  <= shift_reg_stage1_buf[3] + shift_reg_stage1_buf[2] + shift_reg_stage1_buf[1] + shift_reg_stage1_buf[0];
            popcount_high_stage2 <= shift_reg_stage1_buf[7] + shift_reg_stage1_buf[6] + shift_reg_stage1_buf[5] + shift_reg_stage1_buf[4];

            // Stage 3: Combine popcount results
            total_popcount_stage3 <= {1'b0, popcount_low_stage2} + {1'b0, popcount_high_stage2};

            // Stage 4: Majority detection
            reset_detected_stage4 <= (total_popcount_stage3 >= 5);

            // Stage 5: Hysteresis logic and storing MSBs of shift_reg
            shift_reg_top2_stage5 <= shift_reg_stage1_buf[7:6];
            if (reset_detected_stage4_buf && filtered_reset_stage5)
                filtered_reset_stage5 <= 1'b1;
            else if (reset_detected_stage4_buf && !filtered_reset_stage5)
                filtered_reset_stage5 <= 1'b1;
            else if (!reset_detected_stage4_buf && filtered_reset_stage5)
                filtered_reset_stage5 <= shift_reg_top2_stage5 != 2'b00;
            else
                filtered_reset_stage5 <= 1'b0;
        end
    end

endmodule