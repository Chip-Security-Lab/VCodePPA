//SystemVerilog
`timescale 1ns / 1ps

module combo_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 16
)(
    input                       ACLK,
    input                       ARESETN,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input                       S_AXI_AWVALID,
    output                      S_AXI_AWREADY,

    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input                       S_AXI_WVALID,
    output                      S_AXI_WREADY,

    // AXI4-Lite Write Response Channel
    output [1:0]                S_AXI_BRESP,
    output                      S_AXI_BVALID,
    input                       S_AXI_BREADY,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input                       S_AXI_ARVALID,
    output                      S_AXI_ARREADY,

    // AXI4-Lite Read Data Channel
    output [DATA_WIDTH-1:0]     S_AXI_RDATA,
    output [1:0]                S_AXI_RRESP,
    output                      S_AXI_RVALID,
    input                       S_AXI_RREADY
);

    // Internal register addresses
    localparam ADDR_DATA      = 4'h0;
    localparam ADDR_SHIFT_VAL = 4'h4;
    localparam ADDR_OP_MODE   = 4'h8;
    localparam ADDR_RESULT    = 4'hC;

    // AXI4-Lite handshake signals
    reg awready_reg_int;
    reg wready_reg_int;
    reg [1:0] bresp_reg_int;
    reg bvalid_reg_int;
    reg arready_reg;
    reg [15:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;

    // 1st-stage buffer registers for high-fanout signals
    reg [DATA_WIDTH-1:0] s_axi_wdata_buf1;
    reg [(DATA_WIDTH/8)-1:0] s_axi_wstrb_buf1;
    reg awready_buf1;
    reg wready_buf1;
    reg [1:0] bresp_buf1;

    // 2nd-stage buffer registers (optional for further fanout balancing)
    reg [DATA_WIDTH-1:0] s_axi_wdata_buf2;
    reg [(DATA_WIDTH/8)-1:0] s_axi_wstrb_buf2;
    reg awready_buf2;
    reg wready_buf2;
    reg [1:0] bresp_buf2;

    // Assign buffer outputs to AXI interface
    assign S_AXI_AWREADY = awready_buf2;
    assign S_AXI_WREADY  = wready_buf2;
    assign S_AXI_BRESP   = bresp_buf2;
    assign S_AXI_BVALID  = bvalid_reg_int;
    assign S_AXI_ARREADY = arready_reg;
    assign S_AXI_RDATA   = rdata_reg;
    assign S_AXI_RRESP   = rresp_reg;
    assign S_AXI_RVALID  = rvalid_reg;

    // Buffer stages for S_AXI_WDATA and S_AXI_WSTRB
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            s_axi_wdata_buf1 <= {DATA_WIDTH{1'b0}};
            s_axi_wdata_buf2 <= {DATA_WIDTH{1'b0}};
            s_axi_wstrb_buf1 <= {(DATA_WIDTH/8){1'b0}};
            s_axi_wstrb_buf2 <= {(DATA_WIDTH/8){1'b0}};
        end else begin
            s_axi_wdata_buf1 <= S_AXI_WDATA;
            s_axi_wdata_buf2 <= s_axi_wdata_buf1;
            s_axi_wstrb_buf1 <= S_AXI_WSTRB;
            s_axi_wstrb_buf2 <= s_axi_wstrb_buf1;
        end
    end

    // Buffer stages for awready_reg
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            awready_reg_int <= 1'b0;
            awready_buf1    <= 1'b0;
            awready_buf2    <= 1'b0;
        end else begin
            awready_reg_int <= awready_reg_int; // updated in write FSM below
            awready_buf1    <= awready_reg_int;
            awready_buf2    <= awready_buf1;
        end
    end

    // Buffer stages for wready_reg
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            wready_reg_int <= 1'b0;
            wready_buf1    <= 1'b0;
            wready_buf2    <= 1'b0;
        end else begin
            wready_reg_int <= wready_reg_int; // updated in write FSM below
            wready_buf1    <= wready_reg_int;
            wready_buf2    <= wready_buf1;
        end
    end

    // Buffer stages for bresp_reg
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bresp_reg_int <= 2'b00;
            bresp_buf1    <= 2'b00;
            bresp_buf2    <= 2'b00;
        end else begin
            bresp_reg_int <= bresp_reg_int; // updated in write response below
            bresp_buf1    <= bresp_reg_int;
            bresp_buf2    <= bresp_buf1;
        end
    end

    // Write state machine
    reg write_in_progress;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [(DATA_WIDTH/8)-1:0] wstrb_reg;
    reg awvalid_d, wvalid_d;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            awready_reg_int   <= 1'b0;
            wready_reg_int    <= 1'b0;
            bvalid_reg_int    <= 1'b0;
            bresp_reg_int     <= 2'b00;
            write_in_progress <= 1'b0;
            awaddr_reg        <= {ADDR_WIDTH{1'b0}};
            wdata_reg         <= {DATA_WIDTH{1'b0}};
            wstrb_reg         <= {(DATA_WIDTH/8){1'b0}};
            awvalid_d         <= 1'b0;
            wvalid_d          <= 1'b0;
        end else begin
            // Capture address and data at handshake, move reg after combo logic
            if (!awready_reg_int && S_AXI_AWVALID && !write_in_progress) begin
                awready_reg_int <= 1'b1;
                awaddr_reg      <= S_AXI_AWADDR;
                awvalid_d       <= 1'b1;
            end else begin
                awready_reg_int <= 1'b0;
                awvalid_d       <= 1'b0;
            end

            if (!wready_reg_int && S_AXI_WVALID && !write_in_progress) begin
                wready_reg_int <= 1'b1;
                wdata_reg      <= s_axi_wdata_buf2;
                wstrb_reg      <= s_axi_wstrb_buf2;
                wvalid_d       <= 1'b1;
            end else begin
                wready_reg_int <= 1'b0;
                wvalid_d       <= 1'b0;
            end

            if ((awvalid_d || awready_reg_int) && (wvalid_d || wready_reg_int) && !write_in_progress) begin
                write_in_progress <= 1'b1;
            end

            // Write response
            if (bvalid_reg_int && S_AXI_BREADY) begin
                bvalid_reg_int    <= 1'b0;
                write_in_progress <= 1'b0;
            end
        end
    end

    // Registers moved after combo decode logic
    reg [15:0] reg_data;
    reg [3:0]  reg_shift_val;
    reg [1:0]  reg_op_mode;
    reg [15:0] reg_result;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            reg_data      <= 16'b0;
            reg_shift_val <= 4'b0;
            reg_op_mode   <= 2'b0;
        end else begin
            if (awvalid_d && wvalid_d && !write_in_progress) begin
                case (awaddr_reg)
                    ADDR_DATA: begin
                        if (wstrb_reg[1]) reg_data[15:8]  <= wdata_reg[15:8];
                        if (wstrb_reg[0]) reg_data[7:0]   <= wdata_reg[7:0];
                    end
                    ADDR_SHIFT_VAL: begin
                        if (wstrb_reg[0]) reg_shift_val   <= wdata_reg[3:0];
                    end
                    ADDR_OP_MODE: begin
                        if (wstrb_reg[0]) reg_op_mode     <= wdata_reg[1:0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Write response generation after register update
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bresp_reg_int  <= 2'b00;
            bvalid_reg_int <= 1'b0;
        end else begin
            if (awvalid_d && wvalid_d && !write_in_progress) begin
                bresp_reg_int  <= 2'b00; // OKAY
                bvalid_reg_int <= 1'b1;
            end
        end
    end

    // Read state machine
    reg read_in_progress;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg arvalid_d;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            arready_reg       <= 1'b0;
            rvalid_reg        <= 1'b0;
            rresp_reg         <= 2'b00;
            rdata_reg         <= 16'b0;
            read_in_progress  <= 1'b0;
            araddr_reg        <= {ADDR_WIDTH{1'b0}};
            arvalid_d         <= 1'b0;
        end else begin
            if (!arready_reg && S_AXI_ARVALID && !read_in_progress) begin
                arready_reg      <= 1'b1;
                araddr_reg       <= S_AXI_ARADDR;
                arvalid_d        <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
                arvalid_d   <= 1'b0;
            end

            if (arvalid_d && !read_in_progress) begin
                read_in_progress <= 1'b1;
            end

            if (rvalid_reg && S_AXI_RREADY) begin
                rvalid_reg       <= 1'b0;
                read_in_progress <= 1'b0;
            end
        end
    end

    // Read data register after decode logic
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            rdata_reg  <= 16'b0;
            rresp_reg  <= 2'b00;
            rvalid_reg <= 1'b0;
        end else begin
            if (arvalid_d && !read_in_progress) begin
                case (araddr_reg)
                    ADDR_DATA:      rdata_reg <= reg_data;
                    ADDR_SHIFT_VAL: rdata_reg <= {12'b0, reg_shift_val};
                    ADDR_OP_MODE:   rdata_reg <= {14'b0, reg_op_mode};
                    ADDR_RESULT:    rdata_reg <= reg_result;
                    default:        rdata_reg <= 16'b0;
                endcase
                rresp_reg  <= 2'b00; // OKAY
                rvalid_reg <= 1'b1;
            end
        end
    end

    // Core combo shifter logic, result registered to improve timing
    reg [15:0] reg_result_next;
    always @(*) begin
        case (reg_op_mode)
            2'b00: reg_result_next = reg_data << reg_shift_val;
            2'b01: reg_result_next = reg_data >> reg_shift_val;
            2'b10: reg_result_next = $signed(reg_data) >>> reg_shift_val;
            2'b11: reg_result_next = (reg_data >> reg_shift_val) | (reg_data << (16 - reg_shift_val));
            default: reg_result_next = 16'b0;
        endcase
    end

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            reg_result <= 16'b0;
        end else begin
            reg_result <= reg_result_next;
        end
    end

endmodule