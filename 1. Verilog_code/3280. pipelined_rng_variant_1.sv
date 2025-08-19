//SystemVerilog
module pipelined_rng_axi_stream (
    input  wire         clk,
    input  wire         rst_n,
    // AXI-Stream output interface
    output wire [31:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);
    // Pipeline registers
    reg  [31:0] lfsr_reg_stage1, lfsr_reg_stage2;
    reg  [31:0] shuffle_in_stage3, shuffle_out_stage4;
    reg  [31:0] xor_in_stage5, xor_out_stage6;
    reg  [31:0] add_in_stage7, add_out_stage8;

    // Pipeline valid and tlast signals
    reg         valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg         valid_stage5, valid_stage6, valid_stage7, valid_stage8;
    reg         tlast_stage1, tlast_stage2, tlast_stage3, tlast_stage4;
    reg         tlast_stage5, tlast_stage6, tlast_stage7, tlast_stage8;

    // Stage 1: LFSR feedback calculation (split into two stages for higher Fmax)
    wire [31:0] lfsr_feedback_stage1;
    assign lfsr_feedback_stage1 = {lfsr_reg_stage1[30:0], lfsr_reg_stage1[31] ^ lfsr_reg_stage1[28] ^ 
                                   lfsr_reg_stage1[15] ^ lfsr_reg_stage1[0]};

    // Stage 2: LFSR output register
    // Stage 3: Bit shuffle (split into two stages)
    wire [31:0] shuffle_part1_stage3;
    assign shuffle_part1_stage3 = {lfsr_reg_stage2[15:0], lfsr_reg_stage2[31:16]};
    wire [31:0] shuffle_part2_stage3;
    assign shuffle_part2_stage3 = {shuffle_in_stage3[7:0], shuffle_in_stage3[31:8]};

    // Stage 4: Bit shuffle output
    wire [31:0] shuffle_result_stage4;
    assign shuffle_result_stage4 = shuffle_part1_stage3 ^ shuffle_part2_stage3;

    // Stage 5: Nonlinear transformation - XOR and shift (split into two stages)
    wire [31:0] xor_shift_stage5;
    assign xor_shift_stage5 = shuffle_out_stage4 ^ (shuffle_out_stage4 << 5);

    // Stage 6: Nonlinear transformation - pre-add
    // Stage 7: Nonlinear transformation - add
    wire [31:0] add_result_stage7;
    assign add_result_stage7 = xor_in_stage5 + xor_out_stage6;

    // Stage 8: Output register

    // Pipeline register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Pipeline register resets
            lfsr_reg_stage1      <= 32'h12345678;
            lfsr_reg_stage2      <= 32'h12345678;
            shuffle_in_stage3    <= 32'h87654321;
            shuffle_out_stage4   <= 32'h87654321;
            xor_in_stage5        <= 32'hABCDEF01;
            xor_out_stage6       <= 32'hABCDEF01;
            add_in_stage7        <= 32'h0;
            add_out_stage8       <= 32'h0;

            // Valid signal resets
            valid_stage1         <= 1'b0;
            valid_stage2         <= 1'b0;
            valid_stage3         <= 1'b0;
            valid_stage4         <= 1'b0;
            valid_stage5         <= 1'b0;
            valid_stage6         <= 1'b0;
            valid_stage7         <= 1'b0;
            valid_stage8         <= 1'b0;

            // tlast resets
            tlast_stage1         <= 1'b0;
            tlast_stage2         <= 1'b0;
            tlast_stage3         <= 1'b0;
            tlast_stage4         <= 1'b0;
            tlast_stage5         <= 1'b0;
            tlast_stage6         <= 1'b0;
            tlast_stage7         <= 1'b0;
            tlast_stage8         <= 1'b0;
        end else begin
            // Pipeline advance control: stall whole pipeline unless ready or no valid at output
            if (m_axis_tready || !valid_stage8) begin
                // Stage 1: LFSR feedback calculation
                lfsr_reg_stage1      <= lfsr_feedback_stage1;
                valid_stage1         <= 1'b1;
                tlast_stage1         <= 1'b0;

                // Stage 2: LFSR output register
                lfsr_reg_stage2      <= lfsr_reg_stage1;
                valid_stage2         <= valid_stage1;
                tlast_stage2         <= tlast_stage1;

                // Stage 3: Bit shuffle input register
                shuffle_in_stage3    <= lfsr_reg_stage2;
                valid_stage3         <= valid_stage2;
                tlast_stage3         <= tlast_stage2;

                // Stage 4: Bit shuffle output register
                shuffle_out_stage4   <= shuffle_result_stage4;
                valid_stage4         <= valid_stage3;
                tlast_stage4         <= tlast_stage3;

                // Stage 5: Nonlinear transformation - XOR and shift
                xor_in_stage5        <= shuffle_out_stage4;
                valid_stage5         <= valid_stage4;
                tlast_stage5         <= tlast_stage4;

                // Stage 6: Nonlinear transformation - output from XOR/shift
                xor_out_stage6       <= xor_shift_stage5;
                valid_stage6         <= valid_stage5;
                tlast_stage6         <= tlast_stage5;

                // Stage 7: Nonlinear transformation - pre-add
                add_in_stage7        <= xor_in_stage5;
                valid_stage7         <= valid_stage6;
                tlast_stage7         <= tlast_stage6;

                // Stage 8: Nonlinear transformation - add result
                add_out_stage8       <= add_result_stage7;
                valid_stage8         <= valid_stage7;
                tlast_stage8         <= tlast_stage7;
            end
        end
    end

    assign m_axis_tdata  = add_out_stage8;
    assign m_axis_tvalid = valid_stage8;
    assign m_axis_tlast  = tlast_stage8;

endmodule