//SystemVerilog
module q_format_converter_15_to_31_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    // AXI4-Lite clock and reset
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,

    // AXI4-Lite write address channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                    s_axi_awvalid,
    output reg                     s_axi_awready,

    // AXI4-Lite write data channel
    input  wire [31:0]             s_axi_wdata,
    input  wire [3:0]              s_axi_wstrb,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    // AXI4-Lite write response channel
    output reg [1:0]               s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // AXI4-Lite read address channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                    s_axi_arvalid,
    output reg                     s_axi_arready,

    // AXI4-Lite read data channel
    output reg [31:0]              s_axi_rdata,
    output reg [1:0]               s_axi_rresp,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready
);

    // Internal registers for AXI4-Lite mapped data
    reg [15:0] q15_input_reg_stage1, q15_input_reg_stage2;
    reg [31:0] q31_output_reg_stage1, q31_output_reg_stage2;

    // AXI4-Lite address decode constants
    localparam ADDR_Q15_INPUT  = 4'h0;
    localparam ADDR_Q31_OUTPUT = 4'h4;

    // Write address handshake pipeline
    reg s_axi_awvalid_stage1, s_axi_awvalid_stage2;
    reg [ADDR_WIDTH-1:0] s_axi_awaddr_stage1, s_axi_awaddr_stage2;

    // Write data handshake pipeline
    reg s_axi_wvalid_stage1, s_axi_wvalid_stage2;
    reg [31:0] s_axi_wdata_stage1, s_axi_wdata_stage2;
    reg [3:0]  s_axi_wstrb_stage1, s_axi_wstrb_stage2;

    // Read address handshake pipeline
    reg s_axi_arvalid_stage1, s_axi_arvalid_stage2;
    reg [ADDR_WIDTH-1:0] s_axi_araddr_stage1, s_axi_araddr_stage2;

    // Pipeline for write response
    reg s_axi_bvalid_stage1, s_axi_bvalid_stage2;
    reg [1:0] s_axi_bresp_stage1, s_axi_bresp_stage2;

    // Pipeline for read response
    reg s_axi_rvalid_stage1, s_axi_rvalid_stage2;
    reg [31:0] s_axi_rdata_stage1, s_axi_rdata_stage2;
    reg [1:0]  s_axi_rresp_stage1, s_axi_rresp_stage2;

    // Write address handshake - Stage 1
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_awvalid_stage1 <= 1'b0;
            s_axi_awaddr_stage1  <= {ADDR_WIDTH{1'b0}};
        end else if (!s_axi_awready && s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
            s_axi_awvalid_stage1 <= 1'b1;
            s_axi_awaddr_stage1  <= s_axi_awaddr;
        end else begin
            s_axi_awready <= 1'b0;
            if (s_axi_awvalid_stage1)
                s_axi_awvalid_stage1 <= 1'b0;
        end
    end

    // Write address handshake - Stage 2
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awvalid_stage2 <= 1'b0;
            s_axi_awaddr_stage2  <= {ADDR_WIDTH{1'b0}};
        end else begin
            s_axi_awvalid_stage2 <= s_axi_awvalid_stage1;
            s_axi_awaddr_stage2  <= s_axi_awaddr_stage1;
        end
    end

    // Write data handshake - Stage 1
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            s_axi_wvalid_stage1 <= 1'b0;
            s_axi_wdata_stage1  <= 32'b0;
            s_axi_wstrb_stage1  <= 4'b0;
        end else if (!s_axi_wready && s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
            s_axi_wvalid_stage1 <= 1'b1;
            s_axi_wdata_stage1  <= s_axi_wdata;
            s_axi_wstrb_stage1  <= s_axi_wstrb;
        end else begin
            s_axi_wready <= 1'b0;
            if (s_axi_wvalid_stage1)
                s_axi_wvalid_stage1 <= 1'b0;
        end
    end

    // Write data handshake - Stage 2
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wvalid_stage2 <= 1'b0;
            s_axi_wdata_stage2  <= 32'b0;
            s_axi_wstrb_stage2  <= 4'b0;
        end else begin
            s_axi_wvalid_stage2 <= s_axi_wvalid_stage1;
            s_axi_wdata_stage2  <= s_axi_wdata_stage1;
            s_axi_wstrb_stage2  <= s_axi_wstrb_stage1;
        end
    end

    // Write response pipeline - Stage 1
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid_stage1 <= 1'b0;
            s_axi_bresp_stage1  <= 2'b00;
        end else if (s_axi_awvalid_stage2 && s_axi_wvalid_stage2) begin
            s_axi_bvalid_stage1 <= 1'b1;
            s_axi_bresp_stage1  <= 2'b00; // OKAY
        end else if (s_axi_bvalid_stage1 && s_axi_bready) begin
            s_axi_bvalid_stage1 <= 1'b0;
        end
    end

    // Write response pipeline - Stage 2 (output)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            s_axi_bvalid <= s_axi_bvalid_stage1;
            s_axi_bresp  <= s_axi_bresp_stage1;
        end
    end

    // Write data to register - Pipeline stage 1 (address/data decoding)
    reg write_q15_stage1;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_q15_stage1 <= 1'b0;
        end else begin
            write_q15_stage1 <= (s_axi_awvalid_stage2 && s_axi_wvalid_stage2 &&
                                 (s_axi_awaddr_stage2 == ADDR_Q15_INPUT));
        end
    end

    // Write data to register - Pipeline stage 2 (data write)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            q15_input_reg_stage1 <= 16'b0;
        end else if (write_q15_stage1) begin
            q15_input_reg_stage1[15:8] <= s_axi_wstrb_stage2[1] ? s_axi_wdata_stage2[15:8] : q15_input_reg_stage1[15:8];
            q15_input_reg_stage1[7:0]  <= s_axi_wstrb_stage2[0] ? s_axi_wdata_stage2[7:0]  : q15_input_reg_stage1[7:0];
        end
    end

    // Pipeline q15_input_reg to stage2 for conversion
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            q15_input_reg_stage2 <= 16'b0;
        end else begin
            q15_input_reg_stage2 <= q15_input_reg_stage1;
        end
    end

    // Q-format conversion logic - Stage 1: prepare sign/abs, Stage 2: left shift
    reg [15:0] q15_signabs_stage1;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            q15_signabs_stage1 <= 16'b0;
        end else begin
            q15_signabs_stage1 <= {q15_input_reg_stage2[15], q15_input_reg_stage2[14:0]};
        end
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            q31_output_reg_stage1 <= 32'b0;
        end else begin
            q31_output_reg_stage1 <= {q15_signabs_stage1, 16'b0};
        end
    end

    // Pipeline q31_output_reg to stage2 for read
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            q31_output_reg_stage2 <= 32'b0;
        end else begin
            q31_output_reg_stage2 <= q31_output_reg_stage1;
        end
    end

    // Read address handshake - Stage 1
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_arvalid_stage1 <= 1'b0;
            s_axi_araddr_stage1  <= {ADDR_WIDTH{1'b0}};
        end else if (!s_axi_arready && s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
            s_axi_arvalid_stage1 <= 1'b1;
            s_axi_araddr_stage1  <= s_axi_araddr;
        end else begin
            s_axi_arready <= 1'b0;
            if (s_axi_arvalid_stage1)
                s_axi_arvalid_stage1 <= 1'b0;
        end
    end

    // Read address handshake - Stage 2
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arvalid_stage2 <= 1'b0;
            s_axi_araddr_stage2  <= {ADDR_WIDTH{1'b0}};
        end else begin
            s_axi_arvalid_stage2 <= s_axi_arvalid_stage1;
            s_axi_araddr_stage2  <= s_axi_araddr_stage1;
        end
    end

    // Read data pipeline - Stage 1
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid_stage1 <= 1'b0;
            s_axi_rdata_stage1  <= 32'b0;
            s_axi_rresp_stage1  <= 2'b00;
        end else if (s_axi_arvalid_stage2) begin
            s_axi_rvalid_stage1 <= 1'b1;
            case (s_axi_araddr_stage2)
                ADDR_Q15_INPUT:  s_axi_rdata_stage1 <= {16'b0, q15_input_reg_stage2};
                ADDR_Q31_OUTPUT: s_axi_rdata_stage1 <= q31_output_reg_stage2;
                default:         s_axi_rdata_stage1 <= 32'b0;
            endcase
            s_axi_rresp_stage1 <= 2'b00; // OKAY
        end else if (s_axi_rvalid_stage1 && s_axi_rready) begin
            s_axi_rvalid_stage1 <= 1'b0;
        end
    end

    // Read data pipeline - Stage 2 (output)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'b0;
            s_axi_rresp  <= 2'b00;
        end else begin
            s_axi_rvalid <= s_axi_rvalid_stage1;
            s_axi_rdata  <= s_axi_rdata_stage1;
            s_axi_rresp  <= s_axi_rresp_stage1;
        end
    end

endmodule