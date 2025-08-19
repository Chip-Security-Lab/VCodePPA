//SystemVerilog
module biphase_mark_enc_axi_stream #(
    parameter DATA_WIDTH = 1
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready
);

    // Stage 1: Input latch and phase update
    reg [DATA_WIDTH-1:0] s_axis_tdata_stage1;
    reg                  s_axis_tvalid_stage1;
    reg                  phase_stage1;
    reg                  s_axis_tready_reg;

    // Stage 2: Biphase mark encoding output
    reg [DATA_WIDTH-1:0] m_axis_tdata_stage2;
    reg                  m_axis_tvalid_stage2;
    reg                  phase_stage2;

    // Valid chain for pipeline
    reg                  valid_stage1;
    reg                  valid_stage2;

    // Ready chain for pipeline
    wire                 ready_stage1;
    wire                 ready_stage2;

    // Flush/Reset logic
    wire                 flush_pipeline;

    assign flush_pipeline = ~rst_n;

    // Output assignments
    assign m_axis_tdata  = m_axis_tdata_stage2;
    assign m_axis_tvalid = m_axis_tvalid_stage2;
    assign s_axis_tready = s_axis_tready_reg;

    // Stage 2 ready logic (output stage)
    assign ready_stage2 = m_axis_tready | ~m_axis_tvalid;

    // Stage 1 ready logic: allow new data if stage2 is ready to accept
    assign ready_stage1 = ready_stage2;

    // Input ready logic (AXIS handshake)
    always @(*) begin
        if (!rst_n)
            s_axis_tready_reg = 1'b0;
        else
            s_axis_tready_reg = ready_stage1;
    end

    // Stage 1: Input latch and phase update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tdata_stage1   <= {DATA_WIDTH{1'b0}};
            s_axis_tvalid_stage1  <= 1'b0;
            phase_stage1          <= 1'b0;
            valid_stage1          <= 1'b0;
        end else if (ready_stage1) begin
            s_axis_tdata_stage1   <= s_axis_tdata;
            s_axis_tvalid_stage1  <= s_axis_tvalid;
            phase_stage1          <= valid_stage1 ? phase_stage1 : 1'b0; // Reset phase if pipeline is flushed
            valid_stage1          <= s_axis_tvalid & s_axis_tready_reg;
            if (s_axis_tvalid & s_axis_tready_reg)
                phase_stage1      <= ~phase_stage1;
        end else begin
            // Hold values
            s_axis_tdata_stage1   <= s_axis_tdata_stage1;
            s_axis_tvalid_stage1  <= s_axis_tvalid_stage1;
            phase_stage1          <= phase_stage1;
            valid_stage1          <= valid_stage1;
        end
    end

    // Stage 2: Biphase mark encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata_stage2   <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid_stage2  <= 1'b0;
            phase_stage2          <= 1'b0;
            valid_stage2          <= 1'b0;
        end else if (ready_stage2) begin
            m_axis_tvalid_stage2  <= valid_stage1;
            valid_stage2          <= valid_stage1;
            phase_stage2          <= phase_stage1;
            if (valid_stage1) begin
                m_axis_tdata_stage2 <= s_axis_tdata_stage1 ? phase_stage1 : ~phase_stage1;
            end else begin
                m_axis_tdata_stage2 <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            // Hold values
            m_axis_tdata_stage2   <= m_axis_tdata_stage2;
            m_axis_tvalid_stage2  <= m_axis_tvalid_stage2;
            phase_stage2          <= phase_stage2;
            valid_stage2          <= valid_stage2;
        end
    end

endmodule