//SystemVerilog
module decimal_ascii_to_binary #(
    parameter MAX_DIGITS = 3
)(
    input  wire [8*MAX_DIGITS-1:0] ascii_in,
    output reg  [$clog2(10**MAX_DIGITS)-1:0] binary_out,
    output reg  valid
);

    // Stage 1: Extract ASCII codes and decode to 4-bit digits, mark invalids
    reg [3:0]                digit_stage1   [0:MAX_DIGITS-1];
    reg                      valid_stage1   [0:MAX_DIGITS-1];
    integer                  idx_stage1;
    always @* begin : ascii_decode_stage
        for (idx_stage1 = 0; idx_stage1 < MAX_DIGITS; idx_stage1 = idx_stage1 + 1) begin
            digit_stage1[idx_stage1] = ascii_in[8*idx_stage1 +: 8] - 8'h30;
            if (ascii_in[8*idx_stage1 +: 8] == 8'h20) begin // Space, treat as valid, digit=0
                valid_stage1[idx_stage1] = 1'b1;
                digit_stage1[idx_stage1] = 4'd0;
            end else if (digit_stage1[idx_stage1] <= 4'd9) begin
                valid_stage1[idx_stage1] = 1'b1;
            end else begin
                valid_stage1[idx_stage1] = 1'b0;
            end
        end
    end

    // Stage 2: Register digits and valids for pipelining
    reg [3:0]                digit_stage2   [0:MAX_DIGITS-1];
    reg                      valid_stage2   [0:MAX_DIGITS-1];
    integer                  idx_stage2;
    always @* begin : stage2_reg
        for (idx_stage2 = 0; idx_stage2 < MAX_DIGITS; idx_stage2 = idx_stage2 + 1) begin
            digit_stage2[idx_stage2] = digit_stage1[idx_stage2];
            valid_stage2[idx_stage2] = valid_stage1[idx_stage2];
        end
    end

    // Stage 3: Pipeline - Compute binary value with pipelined multiply-accumulate
    reg [$clog2(10**MAX_DIGITS)-1:0] value_stage3 [0:MAX_DIGITS];
    integer                          idx_stage3;

    always @* begin : mac_pipeline_stage
        value_stage3[0] = 0;
        for (idx_stage3 = 0; idx_stage3 < MAX_DIGITS; idx_stage3 = idx_stage3 + 1) begin
            value_stage3[idx_stage3+1] = value_stage3[idx_stage3] * 10 + digit_stage2[idx_stage3];
        end
    end

    // Stage 4: Aggregate valid signal
    integer idx_valid;
    reg all_valid;
    always @* begin : valid_check_stage
        all_valid = 1'b1;
        for (idx_valid = 0; idx_valid < MAX_DIGITS; idx_valid = idx_valid + 1) begin
            if (~valid_stage2[idx_valid])
                all_valid = 1'b0;
        end
    end

    // Stage 5: Output register
    always @* begin : output_stage
        binary_out = value_stage3[MAX_DIGITS];
        valid      = all_valid;
    end

endmodule