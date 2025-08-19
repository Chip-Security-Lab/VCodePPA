//SystemVerilog
module pipelined_barrel_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
) (
    input                       clk,
    input                       rst,

    // AXI4-Lite Write Address Channel
    input       [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                        s_axi_awvalid,
    output reg                   s_axi_awready,

    // AXI4-Lite Write Data Channel
    input       [DATA_WIDTH-1:0] s_axi_wdata,
    input      [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                        s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input                        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input       [ADDR_WIDTH-1:0] s_axi_araddr,
    input                        s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input                        s_axi_rready
);

    // Internal registers for memory-mapped register file
    reg [DATA_WIDTH-1:0] reg_data_in_stage0;
    reg [4:0]            reg_shift_stage0;

    // Pipeline registers for barrel shifter
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg [4:0]            shift_stage1;
    reg                  valid_stage1;

    reg [DATA_WIDTH-1:0] data_in_stage2;
    reg [4:0]            shift_stage2;
    reg                  valid_stage2;

    reg [DATA_WIDTH-1:0] data_in_stage3;
    reg [4:0]            shift_stage3;
    reg                  valid_stage3;

    reg [DATA_WIDTH-1:0] data_out_stage4;
    reg                  valid_stage4;

    reg [DATA_WIDTH-1:0] reg_data_out;

    // Write FSM
    localparam [1:0] WR_IDLE = 2'd0,
                     WR_DATA = 2'd1,
                     WR_RESP = 2'd2;
    reg [1:0] wr_state;
    reg [ADDR_WIDTH-1:0] wr_addr_latched;

    // Read FSM
    localparam [1:0] RD_IDLE = 2'd0,
                     RD_DATA = 2'd1;
    reg [1:0] rd_state;
    reg [ADDR_WIDTH-1:0] rd_addr_latched;

    // Address mapping
    localparam ADDR_DATA_IN  = 4'h0;
    localparam ADDR_SHIFT    = 4'h4;
    localparam ADDR_DATA_OUT = 4'h8;

    // Pipeline valid/flush logic
    reg flush_pipeline;
    reg flush_pipeline_d1, flush_pipeline_d2, flush_pipeline_d3;

    // Address decode
    wire addr_is_data_in  = (s_axi_awaddr == ADDR_DATA_IN);
    wire addr_is_shift    = (s_axi_awaddr == ADDR_SHIFT);

    wire rd_addr_is_data_in  = (s_axi_araddr == ADDR_DATA_IN);
    wire rd_addr_is_shift    = (s_axi_araddr == ADDR_SHIFT);
    wire rd_addr_is_data_out = (s_axi_araddr == ADDR_DATA_OUT);

    // Pipeline flush on reset or write to data_in/shift
    always @(posedge clk) begin
        if (rst) begin
            flush_pipeline <= 1'b1;
        end else if (wr_state == WR_IDLE && s_axi_awvalid && s_axi_wvalid &&
                    (addr_is_data_in || addr_is_shift)) begin
            flush_pipeline <= 1'b1;
        end else begin
            flush_pipeline <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            flush_pipeline_d1 <= 1'b1;
            flush_pipeline_d2 <= 1'b1;
            flush_pipeline_d3 <= 1'b1;
        end else begin
            flush_pipeline_d1 <= flush_pipeline;
            flush_pipeline_d2 <= flush_pipeline_d1;
            flush_pipeline_d3 <= flush_pipeline_d2;
        end
    end

    // AXI4-Lite Write Channel
    always @(posedge clk) begin
        if (rst) begin
            wr_state        <= WR_IDLE;
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            wr_addr_latched <= {ADDR_WIDTH{1'b0}};
            reg_data_in_stage0 <= {DATA_WIDTH{1'b0}};
            reg_shift_stage0   <= 5'd0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    s_axi_bvalid  <= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        wr_addr_latched <= s_axi_awaddr;
                        s_axi_awready   <= 1'b0;
                        s_axi_wready    <= 1'b0;
                        wr_state        <= WR_RESP;
                        if (addr_is_data_in && (s_axi_wstrb[3:0] == 4'b1111)) begin
                            reg_data_in_stage0 <= s_axi_wdata;
                        end
                        else if (addr_is_shift && s_axi_wstrb[0]) begin
                            reg_shift_stage0 <= s_axi_wdata[4:0];
                        end
                    end
                end
                WR_RESP: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00; // OKAY response
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid  <= 1'b0;
                        wr_state      <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // AXI4-Lite Read Channel
    always @(posedge clk) begin
        if (rst) begin
            rd_state        <= RD_IDLE;
            s_axi_arready   <= 1'b0;
            s_axi_rvalid    <= 1'b0;
            s_axi_rresp     <= 2'b00;
            s_axi_rdata     <= {DATA_WIDTH{1'b0}};
            rd_addr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    if (s_axi_arvalid) begin
                        rd_addr_latched <= s_axi_araddr;
                        s_axi_arready   <= 1'b0;
                        rd_state        <= RD_DATA;
                        if (rd_addr_is_data_in) begin
                            s_axi_rdata <= reg_data_in_stage0;
                        end else if (rd_addr_is_shift) begin
                            s_axi_rdata <= {27'd0, reg_shift_stage0};
                        end else if (rd_addr_is_data_out) begin
                            s_axi_rdata <= reg_data_out;
                        end else begin
                            s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        end
                        s_axi_rresp <= 2'b00; // OKAY response
                    end
                end
                RD_DATA: begin
                    s_axi_rvalid <= 1'b1;
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        rd_state     <= RD_IDLE;
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // Barrel shifter 4-stage pipeline
    // Stage 1: Latch input data and shift
    always @(posedge clk) begin
        if (rst || flush_pipeline) begin
            data_in_stage1    <= {DATA_WIDTH{1'b0}};
            shift_stage1      <= 5'd0;
            valid_stage1      <= 1'b0;
        end else begin
            data_in_stage1    <= reg_data_in_stage0;
            shift_stage1      <= reg_shift_stage0;
            valid_stage1      <= 1'b1;
        end
    end

    // Stage 2: Shift by 16 bits if needed
    reg [DATA_WIDTH-1:0] shift_stage2_result;
    always @(*) begin
        if (shift_stage1[4]) begin
            shift_stage2_result = {data_in_stage1[15:0], 16'b0};
        end else begin
            shift_stage2_result = data_in_stage1;
        end
    end
    always @(posedge clk) begin
        if (rst || flush_pipeline_d1) begin
            data_in_stage2    <= {DATA_WIDTH{1'b0}};
            shift_stage2      <= 5'd0;
            valid_stage2      <= 1'b0;
        end else begin
            data_in_stage2    <= shift_stage2_result;
            shift_stage2      <= shift_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3: Shift by 8 bits if needed
    reg [DATA_WIDTH-1:0] shift_stage3_result;
    always @(*) begin
        if (shift_stage2[3]) begin
            shift_stage3_result = {data_in_stage2[23:0], 8'b0};
        end else begin
            shift_stage3_result = data_in_stage2;
        end
    end
    always @(posedge clk) begin
        if (rst || flush_pipeline_d2) begin
            data_in_stage3    <= {DATA_WIDTH{1'b0}};
            shift_stage3      <= 5'd0;
            valid_stage3      <= 1'b0;
        end else begin
            data_in_stage3    <= shift_stage3_result;
            shift_stage3      <= shift_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    // Stage 4: Shift by 4,2,1 bits in parallel
    reg [DATA_WIDTH-1:0] final_shift_result;
    always @(*) begin
        final_shift_result = data_in_stage3;
        if (shift_stage3[2])
            final_shift_result = {final_shift_result[27:0], 4'b0};
        if (shift_stage3[1])
            final_shift_result = {final_shift_result[30:0], 1'b0};
        if (shift_stage3[0])
            final_shift_result = {final_shift_result[DATA_WIDTH-2:0], 1'b0};
    end
    always @(posedge clk) begin
        if (rst || flush_pipeline_d3) begin
            data_out_stage4   <= {DATA_WIDTH{1'b0}};
            valid_stage4      <= 1'b0;
        end else begin
            data_out_stage4   <= final_shift_result;
            valid_stage4      <= valid_stage3;
        end
    end

    // Output register for reg_data_out
    always @(posedge clk) begin
        if (rst) begin
            reg_data_out <= {DATA_WIDTH{1'b0}};
        end else if (valid_stage4) begin
            reg_data_out <= data_out_stage4;
        end
    end

endmodule