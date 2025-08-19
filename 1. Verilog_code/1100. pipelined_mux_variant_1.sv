//SystemVerilog
`timescale 1ns / 1ps

module pipelined_mux_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 16
)(
    input  wire                    clk,
    input  wire                    reset_n,

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
    input  wire                    s_axi_rready
);

    // Internal memory-mapped registers
    reg [DATA_WIDTH-1:0] data_reg_0;
    reg [DATA_WIDTH-1:0] data_reg_1;
    reg [DATA_WIDTH-1:0] data_reg_2;
    reg [DATA_WIDTH-1:0] data_reg_3;

    // Pipeline registers for write channel
    reg [ADDR_WIDTH-1:0] awaddr_stage1;
    reg                  awvalid_stage1;
    reg [DATA_WIDTH-1:0] wdata_stage1;
    reg [(DATA_WIDTH/8)-1:0] wstrb_stage1;
    reg                  wvalid_stage1;
    reg                  write_valid_stage1;
    reg [1:0]            reg_sel_aw_stage1;
    reg                  aw_en_stage1;

    reg [ADDR_WIDTH-1:0] awaddr_stage2;
    reg                  awvalid_stage2;
    reg [DATA_WIDTH-1:0] wdata_stage2;
    reg [(DATA_WIDTH/8)-1:0] wstrb_stage2;
    reg                  wvalid_stage2;
    reg                  write_valid_stage2;
    reg [1:0]            reg_sel_aw_stage2;
    reg                  aw_en_stage2;

    // Pipeline registers for read channel
    reg [ADDR_WIDTH-1:0] araddr_stage1;
    reg                  arvalid_stage1;
    reg [1:0]            reg_sel_ar_stage1;
    reg                  read_valid_stage1;

    reg [ADDR_WIDTH-1:0] araddr_stage2;
    reg                  arvalid_stage2;
    reg [1:0]            reg_sel_ar_stage2;
    reg                  read_valid_stage2;

    reg [DATA_WIDTH-1:0] mux_data_stage3;
    reg [1:0]            reg_sel_ar_stage3;
    reg                  read_valid_stage3;

    // Write address decode
    wire [1:0] reg_sel_aw = s_axi_awaddr[3:2];
    // Read address decode
    wire [1:0] reg_sel_ar = s_axi_araddr[3:2];

    // Write Address/Write Data Pipeline Stage 1
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            awaddr_stage1      <= {ADDR_WIDTH{1'b0}};
            awvalid_stage1     <= 1'b0;
            wdata_stage1       <= {DATA_WIDTH{1'b0}};
            wstrb_stage1       <= {(DATA_WIDTH/8){1'b0}};
            wvalid_stage1      <= 1'b0;
            write_valid_stage1 <= 1'b0;
            reg_sel_aw_stage1  <= 2'b00;
            aw_en_stage1       <= 1'b1;
        end else begin
            if (aw_en_stage1 && s_axi_awvalid && s_axi_wvalid) begin
                awaddr_stage1      <= s_axi_awaddr;
                awvalid_stage1     <= s_axi_awvalid;
                wdata_stage1       <= s_axi_wdata;
                wstrb_stage1       <= s_axi_wstrb;
                wvalid_stage1      <= s_axi_wvalid;
                write_valid_stage1 <= 1'b1;
                reg_sel_aw_stage1  <= reg_sel_aw;
                aw_en_stage1       <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en_stage1       <= 1'b1;
                write_valid_stage1 <= 1'b0;
                awvalid_stage1     <= 1'b0;
                wvalid_stage1      <= 1'b0;
            end else if (!aw_en_stage1) begin
                write_valid_stage1 <= write_valid_stage1;
            end else begin
                write_valid_stage1 <= 1'b0;
                awvalid_stage1     <= 1'b0;
                wvalid_stage1      <= 1'b0;
            end
        end
    end

    // Write Address/Write Data Pipeline Stage 2
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            awaddr_stage2      <= {ADDR_WIDTH{1'b0}};
            awvalid_stage2     <= 1'b0;
            wdata_stage2       <= {DATA_WIDTH{1'b0}};
            wstrb_stage2       <= {(DATA_WIDTH/8){1'b0}};
            wvalid_stage2      <= 1'b0;
            write_valid_stage2 <= 1'b0;
            reg_sel_aw_stage2  <= 2'b00;
            aw_en_stage2       <= 1'b1;
        end else begin
            awaddr_stage2      <= awaddr_stage1;
            awvalid_stage2     <= awvalid_stage1;
            wdata_stage2       <= wdata_stage1;
            wstrb_stage2       <= wstrb_stage1;
            wvalid_stage2      <= wvalid_stage1;
            write_valid_stage2 <= write_valid_stage1;
            reg_sel_aw_stage2  <= reg_sel_aw_stage1;
            aw_en_stage2       <= aw_en_stage1;
        end
    end

    // Write memory-mapped registers at pipeline stage 2
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_reg_0 <= {DATA_WIDTH{1'b0}};
            data_reg_1 <= {DATA_WIDTH{1'b0}};
            data_reg_2 <= {DATA_WIDTH{1'b0}};
            data_reg_3 <= {DATA_WIDTH{1'b0}};
        end else begin
            if (write_valid_stage2 && awvalid_stage2 && wvalid_stage2 && aw_en_stage2) begin
                case (reg_sel_aw_stage2)
                    2'b00: if (wstrb_stage2[1:0] == 2'b11) data_reg_0 <= wdata_stage2;
                    2'b01: if (wstrb_stage2[1:0] == 2'b11) data_reg_1 <= wdata_stage2;
                    2'b10: if (wstrb_stage2[1:0] == 2'b11) data_reg_2 <= wdata_stage2;
                    2'b11: if (wstrb_stage2[1:0] == 2'b11) data_reg_3 <= wdata_stage2;
                endcase
            end
        end
    end

    // Write address handshake (pipeline ready signals)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
        end else begin
            // Ready when stage1 is available to accept new transaction
            s_axi_awready <= aw_en_stage1 && s_axi_wvalid;
            s_axi_wready  <= aw_en_stage1 && s_axi_awvalid;
        end
    end

    // Write response logic (pipeline stage2 output)
    reg bvalid_stage2;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            bvalid_stage2 <= 1'b0;
        end else begin
            if (write_valid_stage2 && awvalid_stage2 && wvalid_stage2 && aw_en_stage2 && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                bvalid_stage2 <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                bvalid_stage2 <= 1'b0;
            end
        end
    end

    // Read Address Pipeline Stage 1
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            araddr_stage1     <= {ADDR_WIDTH{1'b0}};
            arvalid_stage1    <= 1'b0;
            reg_sel_ar_stage1 <= 2'b00;
            read_valid_stage1 <= 1'b0;
        end else begin
            if (!arvalid_stage1 && s_axi_arvalid && !s_axi_rvalid) begin
                araddr_stage1     <= s_axi_araddr;
                arvalid_stage1    <= s_axi_arvalid;
                reg_sel_ar_stage1 <= reg_sel_ar;
                read_valid_stage1 <= 1'b1;
            end else if (read_valid_stage1 && !arvalid_stage2) begin
                read_valid_stage1 <= 1'b0;
                arvalid_stage1    <= 1'b0;
            end
        end
    end

    // Read Address Pipeline Stage 2
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            araddr_stage2     <= {ADDR_WIDTH{1'b0}};
            arvalid_stage2    <= 1'b0;
            reg_sel_ar_stage2 <= 2'b00;
            read_valid_stage2 <= 1'b0;
        end else begin
            araddr_stage2     <= araddr_stage1;
            arvalid_stage2    <= arvalid_stage1;
            reg_sel_ar_stage2 <= reg_sel_ar_stage1;
            read_valid_stage2 <= read_valid_stage1;
        end
    end

    // Read Data Pipeline Stage 3 (Multiplexer)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mux_data_stage3    <= {DATA_WIDTH{1'b0}};
            reg_sel_ar_stage3  <= 2'b00;
            read_valid_stage3  <= 1'b0;
        end else begin
            case (reg_sel_ar_stage2)
                2'b00: mux_data_stage3 <= data_reg_0;
                2'b01: mux_data_stage3 <= data_reg_1;
                2'b10: mux_data_stage3 <= data_reg_2;
                2'b11: mux_data_stage3 <= data_reg_3;
                default: mux_data_stage3 <= {DATA_WIDTH{1'b0}};
            endcase
            reg_sel_ar_stage3  <= reg_sel_ar_stage2;
            read_valid_stage3  <= read_valid_stage2;
        end
    end

    // Read handshake logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axi_arready <= 1'b0;
        end else begin
            s_axi_arready <= !arvalid_stage1 && !s_axi_rvalid;
        end
    end

    // Read data output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
        end else begin
            if (read_valid_stage3 && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= mux_data_stage3;
                s_axi_rresp  <= 2'b00;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Optionally: output the pipeline result for external monitoring
    // output reg [DATA_WIDTH-1:0] result
    // assign result = mux_data_stage3;

endmodule