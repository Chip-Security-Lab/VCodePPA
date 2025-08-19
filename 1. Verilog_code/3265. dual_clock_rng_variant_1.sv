//SystemVerilog
module dual_clock_rng_axi_stream (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        rst,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    // ------- LFSR_A: 2-stage pipeline -------
    reg [15:0] lfsr_a_stage1;
    reg [15:0] lfsr_a_stage2;
    reg        valid_a_stage1;
    reg        valid_a_stage2;

    wire lfsr_a_feedback;
    assign lfsr_a_feedback = lfsr_a_stage1[15] ^ lfsr_a_stage1[14] ^ lfsr_a_stage1[12] ^ lfsr_a_stage1[3];

    always @(posedge clk_a or posedge rst) begin
        if (rst) begin
            lfsr_a_stage1   <= 16'hACE1;
            lfsr_a_stage2   <= 16'hACE1;
            valid_a_stage1  <= 1'b0;
            valid_a_stage2  <= 1'b0;
        end else begin
            valid_a_stage1 <= s_axis_tvalid & s_axis_tready;
            if (s_axis_tvalid & s_axis_tready) begin
                lfsr_a_stage1 <= {lfsr_a_stage1[14:0], lfsr_a_feedback};
            end
            lfsr_a_stage2  <= lfsr_a_stage1;
            valid_a_stage2 <= valid_a_stage1;
        end
    end

    // ------- LFSR_B: 2-stage pipeline -------
    reg [15:0] lfsr_b_stage1;
    reg [15:0] lfsr_b_stage2;
    reg        valid_b_stage1;
    reg        valid_b_stage2;

    wire lfsr_b_feedback;
    assign lfsr_b_feedback = lfsr_b_stage1[15] ^ lfsr_b_stage1[13] ^ lfsr_b_stage1[9] ^ lfsr_b_stage1[2];

    always @(posedge clk_b or posedge rst) begin
        if (rst) begin
            lfsr_b_stage1   <= 16'h1CE2;
            lfsr_b_stage2   <= 16'h1CE2;
            valid_b_stage1  <= 1'b0;
            valid_b_stage2  <= 1'b0;
        end else begin
            valid_b_stage1 <= s_axis_tvalid & s_axis_tready;
            if (s_axis_tvalid & s_axis_tready) begin
                lfsr_b_stage1 <= {lfsr_b_stage1[14:0], lfsr_b_feedback};
            end
            lfsr_b_stage2  <= lfsr_b_stage1;
            valid_b_stage2 <= valid_b_stage1;
        end
    end

    // ------- Output pipeline stage (synchronize on clk_a) -------
    reg [15:0] lfsr_a_final;
    reg [15:0] lfsr_b_final;
    reg        valid_final;
    reg        tvalid_reg;
    reg [31:0] tdata_reg;

    always @(posedge clk_a or posedge rst) begin
        if (rst) begin
            lfsr_a_final <= 16'h0;
            lfsr_b_final <= 16'h0;
            valid_final  <= 1'b0;
            tvalid_reg   <= 1'b0;
            tdata_reg    <= 32'h0;
        end else begin
            lfsr_a_final <= lfsr_a_stage2;
            lfsr_b_final <= lfsr_b_stage2;
            valid_final  <= valid_a_stage2 & valid_b_stage2;
            // AXI-Stream handshake: register output only when ready
            if ((valid_a_stage2 & valid_b_stage2) && m_axis_tready) begin
                tdata_reg  <= {lfsr_a_stage2, lfsr_b_stage2};
                tvalid_reg <= 1'b1;
            end else if (m_axis_tready) begin
                tvalid_reg <= 1'b0;
            end
        end
    end

    // s_axis_tready: accept input only if output is ready to accept data
    assign s_axis_tready = m_axis_tready | ~tvalid_reg;
    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = 1'b1; // Single beat per transfer

endmodule