//SystemVerilog
module pipelined_rng_axi_stream (
    input  wire         clk,
    input  wire         rst_n,
    output wire [31:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);
    // Stage 1 registers
    reg [31:0] lfsr_reg_stage1;
    // Stage 2 registers
    reg [31:0] lfsr_reg_stage2, shuffle_reg_stage2;
    // Stage 3 registers
    reg [31:0] shuffle_reg_stage3, nonlinear_reg_stage3;
    // Output registers
    reg        tvalid_reg_stage3, tlast_reg_stage3;

    wire pipeline_enable;

    // AXI-Stream handshake
    assign pipeline_enable = m_axis_tready;

    // ----------- Stage 1: LFSR -----------
    wire [31:0] lfsr_next_stage1;
    assign lfsr_next_stage1 = {lfsr_reg_stage1[30:0], lfsr_reg_stage1[31] ^ lfsr_reg_stage1[28] ^ lfsr_reg_stage1[15] ^ lfsr_reg_stage1[0]};

    // ----------- Stage 2: Shuffle -----------
    wire [31:0] shuffled_lfsr_stage2, shuffled_shuffle_stage2, shuffle_next_stage2;
    assign shuffled_lfsr_stage2    = {lfsr_reg_stage2[15:0], lfsr_reg_stage2[31:16]};
    assign shuffled_shuffle_stage2 = {shuffle_reg_stage2[7:0], shuffle_reg_stage2[31:8]};
    assign shuffle_next_stage2     = shuffled_lfsr_stage2 ^ shuffled_shuffle_stage2;

    // ----------- Stage 3: Nonlinear -----------
    wire [31:0] nonlinear_xor_shift_stage3, nonlinear_next_stage3;
    assign nonlinear_xor_shift_stage3 = nonlinear_reg_stage3 ^ (nonlinear_reg_stage3 << 5);
    assign nonlinear_next_stage3      = shuffle_reg_stage3 + nonlinear_xor_shift_stage3;

    // ----------------- Pipeline Registers -----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 init
            lfsr_reg_stage1       <= 32'h12345678;
            // Stage 2 init
            lfsr_reg_stage2       <= 32'h12345678;
            shuffle_reg_stage2    <= 32'h87654321;
            // Stage 3 init
            shuffle_reg_stage3    <= 32'h87654321;
            nonlinear_reg_stage3  <= 32'hABCDEF01;
            tvalid_reg_stage3     <= 1'b0;
            tlast_reg_stage3      <= 1'b0;
        end else if (pipeline_enable) begin
            // Stage 1
            lfsr_reg_stage1       <= lfsr_next_stage1;
            // Stage 2
            lfsr_reg_stage2       <= lfsr_reg_stage1;
            shuffle_reg_stage2    <= shuffle_reg_stage3;
            // Stage 3
            shuffle_reg_stage3    <= shuffle_next_stage2;
            nonlinear_reg_stage3  <= nonlinear_next_stage3;
            tvalid_reg_stage3     <= 1'b1;
            tlast_reg_stage3      <= 1'b0; // For continuous stream, tlast is always 0
        end
    end

    assign m_axis_tdata  = nonlinear_reg_stage3;
    assign m_axis_tvalid = tvalid_reg_stage3;
    assign m_axis_tlast  = tlast_reg_stage3;

endmodule