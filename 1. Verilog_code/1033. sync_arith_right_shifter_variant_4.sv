//SystemVerilog
module sync_arith_right_shifter_axi_stream #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // AXI-Stream Slave Interface (Input)
    input  wire [DATA_WIDTH-1:0]   s_axis_tdata,
    input  wire [SHIFT_WIDTH-1:0]  s_axis_tuser, // shift_by mapped to tuser
    input  wire                    s_axis_tvalid,
    output wire                    s_axis_tready,
    input  wire                    s_axis_tlast,

    // AXI-Stream Master Interface (Output)
    output wire [DATA_WIDTH-1:0]   m_axis_tdata,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire                    m_axis_tlast
);

    // Stage 1: Input Latching
    reg  [DATA_WIDTH-1:0]          tdata_stage1;
    reg  [SHIFT_WIDTH-1:0]         tuser_stage1;
    reg                            tlast_stage1;
    reg                            tvalid_stage1;
    wire                           stage1_ready;

    // Stage 2: Computation
    reg  [DATA_WIDTH-1:0]          result_stage2;
    reg                            tlast_stage2;
    reg                            tvalid_stage2;
    wire                           stage2_ready;

    // AXI-Stream handshake for input stage
    assign s_axis_tready = stage1_ready;

    // AXI-Stream handshake for output stage
    assign m_axis_tdata  = result_stage2;
    assign m_axis_tvalid = tvalid_stage2;
    assign m_axis_tlast  = tlast_stage2;

    // Stage 1: Input Latching
    assign stage1_ready = ~tvalid_stage1 | (tvalid_stage1 & stage2_ready);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tdata_stage1   <= {DATA_WIDTH{1'b0}};
            tuser_stage1   <= {SHIFT_WIDTH{1'b0}};
            tlast_stage1   <= 1'b0;
            tvalid_stage1  <= 1'b0;
        end else begin
            if (stage1_ready) begin
                if (s_axis_tvalid) begin
                    tdata_stage1  <= s_axis_tdata;
                    tuser_stage1  <= s_axis_tuser;
                    tlast_stage1  <= s_axis_tlast;
                    tvalid_stage1 <= 1'b1;
                end else begin
                    tvalid_stage1 <= 1'b0;
                    tlast_stage1  <= 1'b0;
                end
            end
        end
    end

    // Stage 2: Computation and Output
    assign stage2_ready = (~tvalid_stage2) | (tvalid_stage2 & m_axis_tready);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2  <= {DATA_WIDTH{1'b0}};
            tlast_stage2   <= 1'b0;
            tvalid_stage2  <= 1'b0;
        end else begin
            if (stage2_ready) begin
                if (tvalid_stage1) begin
                    result_stage2  <= $signed(tdata_stage1) >>> tuser_stage1;
                    tlast_stage2   <= tlast_stage1;
                    tvalid_stage2  <= 1'b1;
                end else begin
                    tvalid_stage2  <= 1'b0;
                    tlast_stage2   <= 1'b0;
                end
            end else if (m_axis_tready) begin
                tvalid_stage2 <= 1'b0;
                tlast_stage2  <= 1'b0;
            end
        end
    end

endmodule