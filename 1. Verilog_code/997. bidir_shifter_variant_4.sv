//SystemVerilog
module bidir_shifter_pipeline #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input                          clk,
    input                          reset_n,
    input                          start,
    input      [DATA_WIDTH-1:0]    data_in,
    input      [SHIFT_WIDTH-1:0]   shift_amount,
    input                          left_right_n,    // 1=left, 0=right
    input                          arithmetic_n,    // 1=arithmetic, 0=logical (right only)
    input                          flush,
    output reg [DATA_WIDTH-1:0]    data_out,
    output reg                     valid_out
);

    // Stage 1: Latch inputs
    reg [DATA_WIDTH-1:0]   data_in_stage1;
    reg [SHIFT_WIDTH-1:0]  shift_amount_stage1;
    reg                    left_right_n_stage1;
    reg                    arithmetic_n_stage1;
    reg                    data_sign_stage1;
    reg                    valid_stage1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_in_stage1        <= {DATA_WIDTH{1'b0}};
            shift_amount_stage1   <= {SHIFT_WIDTH{1'b0}};
            left_right_n_stage1   <= 1'b0;
            arithmetic_n_stage1   <= 1'b0;
            data_sign_stage1      <= 1'b0;
            valid_stage1          <= 1'b0;
        end else if (flush) begin
            valid_stage1          <= 1'b0;
        end else if (start) begin
            data_in_stage1        <= data_in;
            shift_amount_stage1   <= shift_amount;
            left_right_n_stage1   <= left_right_n;
            arithmetic_n_stage1   <= arithmetic_n;
            data_sign_stage1      <= data_in[DATA_WIDTH-1];
            valid_stage1          <= 1'b1;
        end else begin
            valid_stage1          <= 1'b0;
        end
    end

    // Stage 2: Partial shift result pipeline register
    reg [DATA_WIDTH-1:0]   shift_partial_stage2;
    reg [DATA_WIDTH-1:0]   data_in_stage2;
    reg [SHIFT_WIDTH-1:0]  shift_amount_stage2;
    reg                    left_right_n_stage2;
    reg                    arithmetic_n_stage2;
    reg                    data_sign_stage2;
    reg                    valid_stage2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_partial_stage2  <= {DATA_WIDTH{1'b0}};
            data_in_stage2        <= {DATA_WIDTH{1'b0}};
            shift_amount_stage2   <= {SHIFT_WIDTH{1'b0}};
            left_right_n_stage2   <= 1'b0;
            arithmetic_n_stage2   <= 1'b0;
            data_sign_stage2      <= 1'b0;
            valid_stage2          <= 1'b0;
        end else if (flush) begin
            valid_stage2          <= 1'b0;
        end else if (valid_stage1) begin
            // Split shift into two stages for timing
            data_in_stage2        <= data_in_stage1;
            shift_amount_stage2   <= shift_amount_stage1;
            left_right_n_stage2   <= left_right_n_stage1;
            arithmetic_n_stage2   <= arithmetic_n_stage1;
            data_sign_stage2      <= data_sign_stage1;
            if (left_right_n_stage1) begin
                // Left shift: split into two parts
                shift_partial_stage2 <= {data_in_stage1[DATA_WIDTH-2:0], 1'b0}; // shift left by 1 as partial
            end else begin
                // Right shift: split into two parts
                shift_partial_stage2 <= {1'b0, data_in_stage1[DATA_WIDTH-1:1]}; // shift right by 1 as partial
            end
            valid_stage2          <= 1'b1;
        end else begin
            valid_stage2          <= 1'b0;
        end
    end

    // Stage 3: Complete shift and calculate mask for arithmetic right shift
    reg [DATA_WIDTH-1:0]   shift_result_stage3;
    reg [DATA_WIDTH-1:0]   mask_stage3;
    reg [SHIFT_WIDTH-1:0]  shift_amount_stage3;
    reg                    left_right_n_stage3;
    reg                    arithmetic_n_stage3;
    reg                    data_sign_stage3;
    reg                    valid_stage3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_result_stage3   <= {DATA_WIDTH{1'b0}};
            mask_stage3           <= {DATA_WIDTH{1'b0}};
            shift_amount_stage3   <= {SHIFT_WIDTH{1'b0}};
            left_right_n_stage3   <= 1'b0;
            arithmetic_n_stage3   <= 1'b0;
            data_sign_stage3      <= 1'b0;
            valid_stage3          <= 1'b0;
        end else if (flush) begin
            valid_stage3          <= 1'b0;
        end else if (valid_stage2) begin
            shift_amount_stage3   <= shift_amount_stage2;
            left_right_n_stage3   <= left_right_n_stage2;
            arithmetic_n_stage3   <= arithmetic_n_stage2;
            data_sign_stage3      <= data_sign_stage2;
            if (left_right_n_stage2) begin
                // Complete left shift
                shift_result_stage3 <= (shift_partial_stage2 << (shift_amount_stage2 - 1));
            end else begin
                // Complete right shift
                shift_result_stage3 <= (shift_partial_stage2 >> (shift_amount_stage2 - 1));
            end
            // Precompute mask for arithmetic right shift
            if (!left_right_n_stage2 && arithmetic_n_stage2 && data_sign_stage2) begin
                mask_stage3 <= ~({DATA_WIDTH{1'b1}} >> shift_amount_stage2);
            end else begin
                mask_stage3 <= {DATA_WIDTH{1'b0}};
            end
            valid_stage3          <= 1'b1;
        end else begin
            valid_stage3          <= 1'b0;
        end
    end

    // Stage 4: Final output/masking for arithmetic right shift
    reg [DATA_WIDTH-1:0]   data_out_stage4;
    reg                    valid_stage4;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out_stage4   <= {DATA_WIDTH{1'b0}};
            valid_stage4      <= 1'b0;
        end else if (flush) begin
            valid_stage4      <= 1'b0;
        end else if (valid_stage3) begin
            if (!left_right_n_stage3 && arithmetic_n_stage3 && data_sign_stage3) begin
                data_out_stage4 <= shift_result_stage3 | mask_stage3;
            end else begin
                data_out_stage4 <= shift_result_stage3;
            end
            valid_stage4      <= 1'b1;
        end else begin
            valid_stage4      <= 1'b0;
        end
    end

    // Output register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out  <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (flush) begin
            valid_out <= 1'b0;
        end else if (valid_stage4) begin
            data_out  <= data_out_stage4;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule