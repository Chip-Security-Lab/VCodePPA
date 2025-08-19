//SystemVerilog
module bit_sliced_rng (
    input wire clk_i,
    input wire rst_n_i,
    output wire [31:0] rnd_o
);

    // Stage 1: Main LFSR registers
    reg [7:0] slice_reg0_stage1;
    reg [7:0] slice_reg1_stage1;
    reg [7:0] slice_reg2_stage1;
    reg [7:0] slice_reg3_stage1;

    // Stage 2: Buffer registers for high fanout signals
    reg [7:0] slice_reg0_buf_stage2;
    reg [7:0] slice_reg1_buf_stage2;
    reg [7:0] slice_reg2_buf_stage2;
    reg [7:0] slice_reg3_buf_stage2;

    // Stage 3: Final buffer registers for load balancing
    reg [7:0] slice_reg0_buf_stage3;
    reg [7:0] slice_reg1_buf_stage3;
    reg [7:0] slice_reg2_buf_stage3;
    reg [7:0] slice_reg3_buf_stage3;

    // Feedback calculation signals (from stage1 regs)
    wire feedback0_stage1;
    wire feedback1_stage1;
    wire feedback2_stage1;
    wire feedback3_stage1;

    assign feedback0_stage1 = slice_reg0_stage1[7] ^ slice_reg0_stage1[5] ^ slice_reg0_stage1[4] ^ slice_reg0_stage1[3];
    assign feedback1_stage1 = slice_reg1_stage1[7] ^ slice_reg1_stage1[6] ^ slice_reg1_stage1[1] ^ slice_reg1_stage1[0];
    assign feedback2_stage1 = slice_reg2_stage1[7] ^ slice_reg2_stage1[6] ^ slice_reg2_stage1[5] ^ slice_reg2_stage1[0];
    assign feedback3_stage1 = slice_reg3_stage1[7] ^ slice_reg3_stage1[3] ^ slice_reg3_stage1[2] ^ slice_reg3_stage1[1];

    // LFSR update and buffering
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            slice_reg0_stage1      <= 8'h1;
            slice_reg1_stage1      <= 8'h2;
            slice_reg2_stage1      <= 8'h4;
            slice_reg3_stage1      <= 8'h8;

            slice_reg0_buf_stage2  <= 8'h1;
            slice_reg1_buf_stage2  <= 8'h2;
            slice_reg2_buf_stage2  <= 8'h4;
            slice_reg3_buf_stage2  <= 8'h8;

            slice_reg0_buf_stage3  <= 8'h1;
            slice_reg1_buf_stage3  <= 8'h2;
            slice_reg2_buf_stage3  <= 8'h4;
            slice_reg3_buf_stage3  <= 8'h8;
        end else begin
            // Stage 1: LFSR update
            slice_reg0_stage1      <= {slice_reg0_stage1[6:0], feedback0_stage1};
            slice_reg1_stage1      <= {slice_reg1_stage1[6:0], feedback1_stage1};
            slice_reg2_stage1      <= {slice_reg2_stage1[6:0], feedback2_stage1};
            slice_reg3_stage1      <= {slice_reg3_stage1[6:0], feedback3_stage1};
            // Stage 2: Buffer registers for fanout reduction
            slice_reg0_buf_stage2  <= slice_reg0_stage1;
            slice_reg1_buf_stage2  <= slice_reg1_stage1;
            slice_reg2_buf_stage2  <= slice_reg2_stage1;
            slice_reg3_buf_stage2  <= slice_reg3_stage1;
            // Stage 3: Final buffer registers for load balancing
            slice_reg0_buf_stage3  <= slice_reg0_buf_stage2;
            slice_reg1_buf_stage3  <= slice_reg1_buf_stage2;
            slice_reg2_buf_stage3  <= slice_reg2_buf_stage2;
            slice_reg3_buf_stage3  <= slice_reg3_buf_stage2;
        end
    end

    // Output using the final buffered values to reduce fanout and balance load
    assign rnd_o = {slice_reg3_buf_stage3, slice_reg2_buf_stage3, slice_reg1_buf_stage3, slice_reg0_buf_stage3};

endmodule