//SystemVerilog
module param_lfsr_rng #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] SEED = {WIDTH{1'b1}},
    parameter [WIDTH-1:0] TAPS = 16'h8016
)(
    input  wire                  clock,
    input  wire                  reset_n,
    input  wire                  enable,
    input  wire                  flush,
    output wire [WIDTH-1:0]      random_value,
    output wire                  valid
);

    // Stage 1: Register output value (Moved from Stage 3)
    reg [WIDTH-1:0] lfsr_q_stage1;
    reg             valid_stage1;

    // Stage 2: Register input to combinational logic (was Stage 1)
    reg [WIDTH-1:0] lfsr_q_stage2;
    reg             valid_stage2;

    // Stage 3: Register valid after combinational logic (was Stage 2)
    reg             valid_stage3;

    // Combinational feedback calculation for LFSR
    wire feedback_comb;
    assign feedback_comb = ^(lfsr_q_stage2 & TAPS);

    integer i;
    reg [WIDTH-1:0] lfsr_c_comb;
    always @* begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (i == WIDTH-1)
                lfsr_c_comb[i] = feedback_comb;
            else
                lfsr_c_comb[i] = lfsr_q_stage2[i+1];
        end
    end

    // Stage 2: Register input to combinational logic (was Stage 1)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_q_stage2 <= SEED;
            valid_stage2  <= 1'b0;
        end else if (flush) begin
            lfsr_q_stage2 <= SEED;
            valid_stage2  <= 1'b0;
        end else if (enable) begin
            lfsr_q_stage2 <= lfsr_q_stage1;
            valid_stage2  <= valid_stage1;
        end else begin
            valid_stage2  <= 1'b0;
        end
    end

    // Stage 1: Register output value (Moved from Stage 3)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_q_stage1 <= SEED;
            valid_stage1  <= 1'b0;
        end else if (flush) begin
            lfsr_q_stage1 <= SEED;
            valid_stage1  <= 1'b0;
        end else if (valid_stage3) begin
            lfsr_q_stage1 <= lfsr_c_comb;
            valid_stage1  <= 1'b1;
        end else begin
            valid_stage1  <= 1'b0;
        end
    end

    // Stage 3: Register valid after combinational logic (was Stage 2)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            valid_stage3 <= 1'b0;
        end else if (flush) begin
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    assign random_value = lfsr_q_stage1;
    assign valid        = valid_stage1;

endmodule