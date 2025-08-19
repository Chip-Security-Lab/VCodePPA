//SystemVerilog
module ChannelEqualizer #(
    parameter WIDTH = 8
) (
    input                      clk,
    input                      rst_n,
    input                      in_valid,
    input  signed [WIDTH-1:0]  rx_sample,
    output reg                 out_valid,
    output reg [WIDTH-1:0]     eq_output
);

    // Stage 1: Shift register for taps
    reg signed [WIDTH-1:0] tap_reg_0, tap_reg_1, tap_reg_2, tap_reg_3, tap_reg_4;
    reg                    valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tap_reg_0 <= {WIDTH{1'b0}};
            tap_reg_1 <= {WIDTH{1'b0}};
            tap_reg_2 <= {WIDTH{1'b0}};
            tap_reg_3 <= {WIDTH{1'b0}};
            tap_reg_4 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (in_valid) begin
            tap_reg_4 <= tap_reg_3;
            tap_reg_3 <= tap_reg_2;
            tap_reg_2 <= tap_reg_1;
            tap_reg_1 <= tap_reg_0;
            tap_reg_0 <= rx_sample;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Pipeline register for taps
    reg signed [WIDTH-1:0] tap_pipe_0, tap_pipe_1, tap_pipe_2, tap_pipe_3, tap_pipe_4;
    reg                    valid_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tap_pipe_0 <= {WIDTH{1'b0}};
            tap_pipe_1 <= {WIDTH{1'b0}};
            tap_pipe_2 <= {WIDTH{1'b0}};
            tap_pipe_3 <= {WIDTH{1'b0}};
            tap_pipe_4 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            tap_pipe_0 <= tap_reg_0;
            tap_pipe_1 <= tap_reg_1;
            tap_pipe_2 <= tap_reg_2;
            tap_pipe_3 <= tap_reg_3;
            tap_pipe_4 <= tap_reg_4;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Precompute tap1+tap2 and tap0+tap3, then multiply (path balancing)
    reg signed [WIDTH:0]    sum_tap1_tap2_stage3;
    reg signed [WIDTH:0]    sum_tap0_tap3_stage3;
    reg signed [WIDTH-1:0]  tap2_stage3;
    reg signed [WIDTH-1:0]  tap4_stage3;
    reg                     valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_tap1_tap2_stage3 <= {(WIDTH+1){1'b0}};
            sum_tap0_tap3_stage3 <= {(WIDTH+1){1'b0}};
            tap2_stage3 <= {WIDTH{1'b0}};
            tap4_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            sum_tap1_tap2_stage3 <= tap_pipe_1 + tap_pipe_2;
            sum_tap0_tap3_stage3 <= tap_pipe_0 + tap_pipe_3;
            tap2_stage3          <= tap_pipe_2;
            tap4_stage3          <= tap_pipe_4;
            valid_stage3         <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Multiply and path balance
    // (tap1 + tap2) * 3, (tap0 + tap3) * -1, tap2 * 3, tap4 (delay only)
    reg signed [WIDTH+2:0] mul_sum12_3_stage4;
    reg signed [WIDTH+2:0] mul_sum03_n1_stage4;
    reg signed [WIDTH+2:0] mul_tap2_3_stage4;
    reg signed [WIDTH-1:0] tap4_stage4;
    reg                    valid_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_sum12_3_stage4   <= {(WIDTH+3){1'b0}};
            mul_sum03_n1_stage4  <= {(WIDTH+3){1'b0}};
            mul_tap2_3_stage4    <= {(WIDTH+3){1'b0}};
            tap4_stage4          <= {WIDTH{1'b0}};
            valid_stage4         <= 1'b0;
        end else if (valid_stage3) begin
            mul_sum12_3_stage4   <= sum_tap1_tap2_stage3 * 3;
            mul_sum03_n1_stage4  <= sum_tap0_tap3_stage3 * (-1);
            mul_tap2_3_stage4    <= tap2_stage3 * 3;
            tap4_stage4          <= tap4_stage3;
            valid_stage4         <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end

    // Stage 5: Compute balanced partial sums
    reg signed [WIDTH+3:0] sum_left_stage5, sum_right_stage5;
    reg                    valid_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_left_stage5  <= {(WIDTH+4){1'b0}};
            sum_right_stage5 <= {(WIDTH+4){1'b0}};
            valid_stage5     <= 1'b0;
        end else if (valid_stage4) begin
            sum_left_stage5  <= mul_sum12_3_stage4 + mul_sum03_n1_stage4;
            sum_right_stage5 <= mul_tap2_3_stage4 + tap4_stage4;
            valid_stage5     <= 1'b1;
        end else begin
            valid_stage5 <= 1'b0;
        end
    end

    // Stage 6: Final sum and shift
    reg signed [WIDTH+4:0] eq_sum_stage6;
    reg                    valid_stage6;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_sum_stage6 <= {(WIDTH+5){1'b0}};
            valid_stage6  <= 1'b0;
        end else if (valid_stage5) begin
            eq_sum_stage6 <= sum_left_stage5 + sum_right_stage5;
            valid_stage6  <= 1'b1;
        end else begin
            valid_stage6 <= 1'b0;
        end
    end

    // Stage 7: Output result (arithmetic right shift)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_output <= {WIDTH{1'b0}};
            out_valid <= 1'b0;
        end else if (valid_stage6) begin
            eq_output <= eq_sum_stage6 >>> 2;
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end

endmodule