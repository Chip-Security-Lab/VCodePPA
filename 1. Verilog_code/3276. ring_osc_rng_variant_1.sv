//SystemVerilog
module ring_osc_rng_pipeline (
    input  wire        system_clk,
    input  wire        reset_n,
    output reg  [7:0]  random_byte_out,
    output reg         valid_out
);
    // Pipeline Stage 1: Oscillator Counter Update
    reg  [3:0] osc_counters_stage1 [3:0];
    reg        valid_stage1;

    integer i;
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                osc_counters_stage1[i] <= i + 1;
            end
            valid_stage1 <= 1'b0;
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                osc_counters_stage1[i] <= osc_counters_stage1[i] + (i + 1);
            end
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline Stage 2: Oscillator Bits Extraction
    reg  [3:0] osc_bits_stage2;
    reg        valid_stage2;

    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            osc_bits_stage2 <= 4'b0000;
            valid_stage2    <= 1'b0;
        end else begin
            osc_bits_stage2[0] <= osc_counters_stage1[0][3];
            osc_bits_stage2[1] <= osc_counters_stage1[1][3];
            osc_bits_stage2[2] <= osc_counters_stage1[2][3];
            osc_bits_stage2[3] <= osc_counters_stage1[3][3];
            valid_stage2       <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Random Byte Construction
    reg  [7:0] random_byte_stage3;
    reg        valid_stage3;

    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            random_byte_stage3 <= 8'h42;
            valid_stage3       <= 1'b0;
        end else if (valid_stage2) begin
            random_byte_stage3 <= {random_byte_stage3[3:0], osc_bits_stage2};
            valid_stage3       <= 1'b1;
        end else begin
            valid_stage3       <= 1'b0;
        end
    end

    // Pipeline Output Register
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            random_byte_out <= 8'h42;
            valid_out       <= 1'b0;
        end else if (valid_stage3) begin
            random_byte_out <= random_byte_stage3;
            valid_out       <= 1'b1;
        end else begin
            valid_out       <= 1'b0;
        end
    end

endmodule