//SystemVerilog
module triangular_dist_rng_pipeline (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,
    output wire [7:0]  random_num,
    output wire        valid_out
);
    // Stage 1: LFSR update
    reg [7:0] lfsr1_stage1, lfsr2_stage1;
    reg       valid_stage1;

    // Stage 2: LFSR output register
    reg [7:0] lfsr1_stage2, lfsr2_stage2;
    reg       valid_stage2;

    // Stage 3: Adder output register
    reg [8:0] sum_stage3;
    reg       valid_stage3;

    // Stage 4: Final output register (averaging)
    reg [7:0] random_num_stage4;
    reg       valid_stage4;

    // Optimized LFSR next state logic using direct XOR reduction
    wire lfsr1_feedback = ^{lfsr1_stage1[7], lfsr1_stage1[5], lfsr1_stage1[4], lfsr1_stage1[3]};
    wire lfsr2_feedback = ^{lfsr2_stage1[7], lfsr2_stage1[6], lfsr2_stage1[5], lfsr2_stage1[0]};
    wire [7:0] lfsr1_next = {lfsr1_stage1[6:0], lfsr1_feedback};
    wire [7:0] lfsr2_next = {lfsr2_stage1[6:0], lfsr2_feedback};

    // Stage 1: Initialization and LFSR update
    always @(posedge clock) begin
        if (reset) begin
            lfsr1_stage1 <= 8'h01;
            lfsr2_stage1 <= 8'hFF;
            valid_stage1 <= 1'b0;
        end else if (start) begin
            lfsr1_stage1 <= lfsr1_next;
            lfsr2_stage1 <= lfsr2_next;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Register LFSR outputs
    always @(posedge clock) begin
        if (reset) begin
            lfsr1_stage2 <= 8'd0;
            lfsr2_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            lfsr1_stage2 <= lfsr1_stage1;
            lfsr2_stage2 <= lfsr2_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Add LFSR outputs with efficient sum and range check (no range chain needed here)
    always @(posedge clock) begin
        if (reset) begin
            sum_stage3   <= 9'd0;
            valid_stage3 <= 1'b0;
        end else begin
            sum_stage3   <= {1'b0, lfsr1_stage2} + {1'b0, lfsr2_stage2};
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Averaging and output register
    always @(posedge clock) begin
        if (reset) begin
            random_num_stage4 <= 8'd0;
            valid_stage4      <= 1'b0;
        end else begin
            random_num_stage4 <= sum_stage3[8:1];
            valid_stage4      <= valid_stage3;
        end
    end

    assign random_num = random_num_stage4;
    assign valid_out  = valid_stage4;

endmodule