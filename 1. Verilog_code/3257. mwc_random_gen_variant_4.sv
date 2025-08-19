//SystemVerilog
module mwc_random_gen (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,
    output wire [31:0] random_data,
    output wire        random_valid
);

    // Stage 1 registers
    reg [31:0] mw_stage1, mz_stage1;
    reg        valid_stage1;

    // Stage 2 registers (mask and shift)
    reg [15:0] mz_low16_stage2, mw_low16_stage2;
    reg [15:0] mz_high16_stage2, mw_high16_stage2;
    reg        valid_stage2;

    // Stage 3 registers (multiplication and addition)
    reg [31:0] mz_mult_stage3, mw_mult_stage3;
    reg [15:0] mz_sum_stage3, mw_sum_stage3;
    reg        valid_stage3;

    // Stage 4 registers (next state, output calculation)
    reg [31:0] mz_next_stage4, mw_next_stage4;
    reg [31:0] random_data_stage4;
    reg        valid_stage4;

    // Constants for multipliers
    localparam [15:0] MZ_CONST = 16'd36969;
    localparam [15:0] MW_CONST = 16'd18000;

    // Pipeline Stage 1: Latch previous state or reset/init
    always @(posedge clock) begin
        if (reset) begin
            mw_stage1     <= 32'h12345678;
            mz_stage1     <= 32'h87654321;
            valid_stage1  <= 1'b0;
        end else if (start) begin
            mw_stage1     <= mw_next_stage4;
            mz_stage1     <= mz_next_stage4;
            valid_stage1  <= 1'b1;
        end else begin
            valid_stage1  <= 1'b0;
        end
    end

    // Pipeline Stage 2: Parallel mask and shift extraction
    always @(posedge clock) begin
        if (reset) begin
            mz_low16_stage2  <= 16'b0;
            mz_high16_stage2 <= 16'b0;
            mw_low16_stage2  <= 16'b0;
            mw_high16_stage2 <= 16'b0;
            valid_stage2     <= 1'b0;
        end else begin
            mz_low16_stage2  <= mz_stage1[15:0];
            mz_high16_stage2 <= mz_stage1[31:16];
            mw_low16_stage2  <= mw_stage1[15:0];
            mw_high16_stage2 <= mw_stage1[31:16];
            valid_stage2     <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Parallel multiplication
    always @(posedge clock) begin
        if (reset) begin
            mz_mult_stage3   <= 32'b0;
            mw_mult_stage3   <= 32'b0;
            mz_sum_stage3    <= 16'b0;
            mw_sum_stage3    <= 16'b0;
            valid_stage3     <= 1'b0;
        end else begin
            mz_mult_stage3   <= MZ_CONST * mz_low16_stage2;
            mw_mult_stage3   <= MW_CONST * mw_low16_stage2;
            mz_sum_stage3    <= mz_high16_stage2;
            mw_sum_stage3    <= mw_high16_stage2;
            valid_stage3     <= valid_stage2;
        end
    end

    // Pipeline Stage 4: Addition and state update, output calculation
    always @(posedge clock) begin
        if (reset) begin
            mz_next_stage4      <= 32'h87654321;
            mw_next_stage4      <= 32'h12345678;
            random_data_stage4  <= 32'b0;
            valid_stage4        <= 1'b0;
        end else begin
            mz_next_stage4      <= mz_mult_stage3 + {16'b0, mz_sum_stage3};
            mw_next_stage4      <= mw_mult_stage3 + {16'b0, mw_sum_stage3};
            random_data_stage4  <= ({mz_next_stage4[15:0], 16'b0}) + mw_next_stage4;
            valid_stage4        <= valid_stage3;
        end
    end

    assign random_data  = random_data_stage4;
    assign random_valid = valid_stage4;

endmodule