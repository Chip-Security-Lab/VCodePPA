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
    output wire                  valid_out
);

    // Stage 1: Tap XOR calculation - register moved forward
    reg  [WIDTH-1:0]    lfsr_q_stage1;
    reg                 valid_stage1;
    wire [WIDTH-1:0]    tap_and_stage1;
    wire                feedback_stage1;

    assign tap_and_stage1 = lfsr_q_stage1 & TAPS;
    assign feedback_stage1 = ^tap_and_stage1;

    // Stage 2: LFSR next-state calculation - register moved forward
    wire [WIDTH-1:0]    lfsr_c_stage2;
    reg  [WIDTH-1:0]    lfsr_q_stage2;
    reg                 valid_stage2;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_lfsr_c_stage2
            if (i == WIDTH-1)
                assign lfsr_c_stage2[i] = feedback_stage1;
            else
                assign lfsr_c_stage2[i] = lfsr_q_stage1[i+1];
        end
    endgenerate

    // Stage 3: Output path - register removed, wires only
    wire [WIDTH-1:0]    lfsr_q_stage3_wire;
    wire                valid_stage3_wire;

    assign lfsr_q_stage3_wire = lfsr_q_stage2;
    assign valid_stage3_wire  = valid_stage2;

    // Stage 1: Register input or seed
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_q_stage1 <= SEED;
            valid_stage1  <= 1'b0;
        end else if (flush) begin
            lfsr_q_stage1 <= SEED;
            valid_stage1  <= 1'b0;
        end else if (enable) begin
            lfsr_q_stage1 <= lfsr_q_stage2;
            valid_stage1  <= valid_stage2;
        end
    end

    // Stage 2: Register feedback and next value (register moved forward)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_q_stage2 <= SEED;
            valid_stage2  <= 1'b0;
        end else if (flush) begin
            lfsr_q_stage2 <= SEED;
            valid_stage2  <= 1'b0;
        end else if (enable) begin
            lfsr_q_stage2 <= lfsr_c_stage2;
            valid_stage2  <= valid_stage1;
        end
    end

    assign random_value = lfsr_q_stage3_wire;
    assign valid_out    = valid_stage3_wire;

endmodule