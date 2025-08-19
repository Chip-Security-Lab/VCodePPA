//SystemVerilog
// Top-level module for pipelined floating-point to fixed-point conversion with synchronization
module fp2fix_sync #(parameter Q = 8)(
    input  wire         clk,
    input  wire         rst,
    input  wire         fp2fix_in_valid,
    input  wire [31:0]  fp,
    output reg          fp2fix_out_valid,
    output reg  [30:0]  fixed
);

    // Stage 1 registers
    reg         sign_stage1_reg;
    reg [7:0]   exp_adj_stage1_reg;
    reg [23:0]  mantissa_stage1_reg;
    reg         valid_stage1_reg;
    reg [31:0]  fp_stage1_reg;

    // Stage 2 registers
    reg         sign_stage2_reg;
    reg [7:0]   exp_adj_stage2_reg;
    reg [23:0]  mantissa_stage2_reg;
    reg [4:0]   shift_amt_stage2_reg;
    reg         valid_stage2_reg;

    // Stage 3 registers
    reg [30:0]  mant_shifted_stage3_reg;
    reg [30:0]  mant_neg_stage3_reg;
    reg         sign_stage3_reg;
    reg         valid_stage3_reg;

    // Stage 4 registers
    reg [30:0]  fixed_stage4_reg;
    reg         valid_stage4_reg;

    // Pipeline flush logic
    wire pipeline_flush;
    assign pipeline_flush = rst;

    // Combinational signals for Stage 1
    wire        sign_stage1_comb;
    wire [7:0]  exp_adj_stage1_comb;
    wire [23:0] mantissa_stage1_comb;
    wire        valid_stage1_comb;
    wire [31:0] fp_stage1_comb;

    assign sign_stage1_comb     = fp[31];
    assign exp_adj_stage1_comb  = fp[30:23] - 8'd127;
    assign mantissa_stage1_comb = {1'b1, fp[22:0]};
    assign valid_stage1_comb    = fp2fix_in_valid;
    assign fp_stage1_comb       = fp;

    // Stage 1 Registers: Field Extraction
    always @(posedge clk) begin
        if (pipeline_flush) begin
            sign_stage1_reg     <= 1'b0;
            exp_adj_stage1_reg  <= 8'b0;
            mantissa_stage1_reg <= 24'b0;
            valid_stage1_reg    <= 1'b0;
            fp_stage1_reg       <= 32'b0;
        end else begin
            sign_stage1_reg     <= sign_stage1_comb;
            exp_adj_stage1_reg  <= exp_adj_stage1_comb;
            mantissa_stage1_reg <= mantissa_stage1_comb;
            valid_stage1_reg    <= valid_stage1_comb;
            fp_stage1_reg       <= fp_stage1_comb;
        end
    end

    // Combinational signals for Stage 2
    wire        sign_stage2_comb;
    wire [7:0]  exp_adj_stage2_comb;
    wire [23:0] mantissa_stage2_comb;
    wire [4:0]  shift_amt_stage2_comb;
    wire        valid_stage2_comb;

    assign sign_stage2_comb     = sign_stage1_reg;
    assign exp_adj_stage2_comb  = exp_adj_stage1_reg;
    assign mantissa_stage2_comb = mantissa_stage1_reg;
    assign valid_stage2_comb    = valid_stage1_reg;
    assign shift_amt_stage2_comb =
        (exp_adj_stage1_reg > 8'd31) ? 5'd31 :
        (exp_adj_stage1_reg[7] == 1'b1 || exp_adj_stage1_reg < Q[7:0]) ? 5'd0 :
        (exp_adj_stage1_reg[4:0] - Q[4:0]);

    // Stage 2 Registers: Shift Amount Calculation
    always @(posedge clk) begin
        if (pipeline_flush) begin
            sign_stage2_reg     <= 1'b0;
            exp_adj_stage2_reg  <= 8'b0;
            mantissa_stage2_reg <= 24'b0;
            shift_amt_stage2_reg<= 5'b0;
            valid_stage2_reg    <= 1'b0;
        end else begin
            sign_stage2_reg     <= sign_stage2_comb;
            exp_adj_stage2_reg  <= exp_adj_stage2_comb;
            mantissa_stage2_reg <= mantissa_stage2_comb;
            shift_amt_stage2_reg<= shift_amt_stage2_comb;
            valid_stage2_reg    <= valid_stage2_comb;
        end
    end

    // Combinational signals for Stage 3
    wire [30:0] mant_shifted_stage3_comb;
    wire [30:0] mant_neg_stage3_comb;
    wire        sign_stage3_comb;
    wire        valid_stage3_comb;

    assign mant_shifted_stage3_comb = mantissa_stage2_reg << shift_amt_stage2_reg;
    assign mant_neg_stage3_comb     = - (mantissa_stage2_reg << shift_amt_stage2_reg);
    assign sign_stage3_comb         = sign_stage2_reg;
    assign valid_stage3_comb        = valid_stage2_reg;

    // Stage 3 Registers: Mantissa Shift and Negate
    always @(posedge clk) begin
        if (pipeline_flush) begin
            mant_shifted_stage3_reg <= 31'b0;
            mant_neg_stage3_reg     <= 31'b0;
            sign_stage3_reg         <= 1'b0;
            valid_stage3_reg        <= 1'b0;
        end else begin
            mant_shifted_stage3_reg <= mant_shifted_stage3_comb;
            mant_neg_stage3_reg     <= mant_neg_stage3_comb;
            sign_stage3_reg         <= sign_stage3_comb;
            valid_stage3_reg        <= valid_stage3_comb;
        end
    end

    // Combinational signals for Stage 4
    wire [30:0] fixed_stage4_comb;
    wire        valid_stage4_comb;

    assign fixed_stage4_comb = sign_stage3_reg ? mant_neg_stage3_reg : mant_shifted_stage3_reg;
    assign valid_stage4_comb = valid_stage3_reg;

    // Stage 4 Registers: Output Selection
    always @(posedge clk) begin
        if (pipeline_flush) begin
            fixed_stage4_reg <= 31'b0;
            valid_stage4_reg <= 1'b0;
        end else begin
            fixed_stage4_reg <= fixed_stage4_comb;
            valid_stage4_reg <= valid_stage4_comb;
        end
    end

    // Output Register
    always @(posedge clk) begin
        if (pipeline_flush) begin
            fixed            <= 31'b0;
            fp2fix_out_valid <= 1'b0;
        end else begin
            fixed            <= fixed_stage4_reg;
            fp2fix_out_valid <= valid_stage4_reg;
        end
    end

endmodule