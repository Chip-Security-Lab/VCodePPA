//SystemVerilog
`timescale 1ns/1ps
module async_spi_master_axi4lite #(
    parameter ADDR_WIDTH = 4,  // 16 bytes address space (enough for a data reg, ctrl reg, status reg)
    parameter DATA_WIDTH = 16  // 16-bit data bus
)(
    input                   clk,
    input                   rst_n,

    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,
    // Write Data Channel
    input  [DATA_WIDTH-1:0] s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
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
    output [DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready,

    // SPI Interface
    output                  sck,
    output                  ss_n,
    output                  mosi,
    input                   miso
);

    // AXI4-Lite Registers
    localparam REG_DATA_IN_ADDR   = 4'h0;
    localparam REG_DATA_OUT_ADDR  = 4'h4;
    localparam REG_CTRL_ADDR      = 4'h8;
    localparam REG_STATUS_ADDR    = 4'hC;

    reg [DATA_WIDTH-1:0]   reg_data_in;
    reg [DATA_WIDTH-1:0]   reg_data_out;
    reg                    reg_begin_xfer;
    reg                    reg_xfer_done;

    // AXI4-Lite interface signals
    reg                    axi_awready_r;
    reg                    axi_wready_r;
    reg [1:0]              axi_bresp_r;
    reg                    axi_bvalid_r;
    reg                    axi_arready_r;
    reg [DATA_WIDTH-1:0]   axi_rdata_r;
    reg [1:0]              axi_rresp_r;
    reg                    axi_rvalid_r;

    assign s_axi_awready = axi_awready_r;
    assign s_axi_wready  = axi_wready_r;
    assign s_axi_bresp   = axi_bresp_r;
    assign s_axi_bvalid  = axi_bvalid_r;
    assign s_axi_arready = axi_arready_r;
    assign s_axi_rdata   = axi_rdata_r;
    assign s_axi_rresp   = axi_rresp_r;
    assign s_axi_rvalid  = axi_rvalid_r;

    // Write address handshake
    reg aw_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awready_r <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (!axi_awready_r && s_axi_awvalid && aw_en) begin
                axi_awready_r <= 1'b1;
            end else begin
                axi_awready_r <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end else if (s_axi_awvalid && axi_awready_r) begin
                aw_en <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_wready_r <= 1'b0;
        end else begin
            if (!axi_wready_r && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                axi_wready_r <= 1'b1;
            end else begin
                axi_wready_r <= 1'b0;
            end
        end
    end

    // Write response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bvalid_r <= 1'b0;
            axi_bresp_r  <= 2'b00;
        end else begin
            if (axi_awready_r && s_axi_awvalid && axi_wready_r && s_axi_wvalid) begin
                axi_bvalid_r <= 1'b1;
                axi_bresp_r  <= 2'b00;
            end else if (s_axi_bready && axi_bvalid_r) begin
                axi_bvalid_r <= 1'b0;
            end
        end
    end

    // Write logic (registers)
    wire write_en = axi_awready_r && s_axi_awvalid && axi_wready_r && s_axi_wvalid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_in    <= {DATA_WIDTH{1'b0}};
            reg_begin_xfer <= 1'b0;
        end else if (write_en) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:2])
                REG_DATA_IN_ADDR[ADDR_WIDTH-1:2]: begin
                    if (s_axi_wstrb[1]) reg_data_in[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) reg_data_in[7:0]  <= s_axi_wdata[7:0];
                end
                REG_CTRL_ADDR[ADDR_WIDTH-1:2]: begin
                    if (s_axi_wstrb[0]) reg_begin_xfer <= s_axi_wdata[0];
                end
                default: ;
            endcase
        end else if (reg_xfer_done) begin
            reg_begin_xfer <= 1'b0;
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_arready_r <= 1'b0;
        end else begin
            if (!axi_arready_r && s_axi_arvalid) begin
                axi_arready_r <= 1'b1;
            end else begin
                axi_arready_r <= 1'b0;
            end
        end
    end

    // Read data logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_rvalid_r <= 1'b0;
            axi_rresp_r  <= 2'b00;
            axi_rdata_r  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (axi_arready_r && s_axi_arvalid) begin
                axi_rvalid_r <= 1'b1;
                axi_rresp_r  <= 2'b00;
                case (s_axi_araddr[ADDR_WIDTH-1:2])
                    REG_DATA_OUT_ADDR[ADDR_WIDTH-1:2]: axi_rdata_r <= reg_data_out;
                    REG_STATUS_ADDR[ADDR_WIDTH-1:2]:   axi_rdata_r <= {15'd0, reg_xfer_done};
                    default:                           axi_rdata_r <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (axi_rvalid_r && s_axi_rready) begin
                axi_rvalid_r <= 1'b0;
            end
        end
    end

    // SPI core logic (from original)
    reg [15:0] shift_reg_stage1, shift_reg_stage2;
    reg [4:0]  bit_cnt_stage1, bit_cnt_stage2;
    reg        running_stage1, running_stage2;
    reg        sck_r_stage1, sck_r_stage2;
    reg        miso_sampled_stage1, miso_sampled_stage2;

    reg [15:0] data_out_r;
    reg        xfer_done_r;
    reg        ss_n_r;
    reg        sck_r_out;
    reg        mosi_r;

    // Pipeline Stage 1: Control and bit count logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1      <= 16'd0;
            bit_cnt_stage1        <= 5'd0;
            running_stage1        <= 1'b0;
            sck_r_stage1          <= 1'b0;
            miso_sampled_stage1   <= 1'b0;
        end else if (!running_stage1 && reg_begin_xfer) begin
            shift_reg_stage1      <= reg_data_in;
            bit_cnt_stage1        <= 5'd16;
            running_stage1        <= 1'b1;
            sck_r_stage1          <= 1'b0;
            miso_sampled_stage1   <= 1'b0;
        end else if (running_stage1) begin
            sck_r_stage1 <= ~sck_r_stage1;
            if (sck_r_stage1) begin // falling edge
                if (bit_cnt_stage1 == 0)
                    running_stage1 <= 1'b0;
                else
                    bit_cnt_stage1 <= bit_cnt_stage1 - 5'd1;
                shift_reg_stage1 <= shift_reg_stage1;
                miso_sampled_stage1 <= miso_sampled_stage1;
            end else begin // rising edge
                shift_reg_stage1 <= {shift_reg_stage1[14:0], miso};
                miso_sampled_stage1 <= miso;
            end
        end
    end

    // Pipeline Stage 2: Output register and further logic (cut-point)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2    <= 16'd0;
            bit_cnt_stage2      <= 5'd0;
            running_stage2      <= 1'b0;
            sck_r_stage2        <= 1'b0;
            miso_sampled_stage2 <= 1'b0;
        end else begin
            shift_reg_stage2    <= shift_reg_stage1;
            bit_cnt_stage2      <= bit_cnt_stage1;
            running_stage2      <= running_stage1;
            sck_r_stage2        <= sck_r_stage1;
            miso_sampled_stage2 <= miso_sampled_stage1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_r   <= 16'd0;
            xfer_done_r  <= 1'b1;
            ss_n_r       <= 1'b1;
            sck_r_out    <= 1'b0;
            mosi_r       <= 1'b0;
        end else begin
            data_out_r   <= shift_reg_stage2;
            xfer_done_r  <= ~running_stage2;
            ss_n_r       <= ~running_stage2;
            sck_r_out    <= running_stage2 ? sck_r_stage2 : 1'b0;
            mosi_r       <= shift_reg_stage2[15];
        end
    end

    // SPI outputs
    assign sck  = sck_r_out;
    assign ss_n = ss_n_r;
    assign mosi = mosi_r;

    // AXI interface <-> SPI output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_out  <= 16'd0;
            reg_xfer_done <= 1'b1;
        end else begin
            reg_data_out  <= data_out_r;
            reg_xfer_done <= xfer_done_r;
        end
    end

endmodule