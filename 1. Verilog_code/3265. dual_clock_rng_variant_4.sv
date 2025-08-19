//SystemVerilog
module dual_clock_rng (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        rst,
    output wire [31:0] random_out
);

    // Stage 1: LFSR state registers (pipeline stage 1)
    reg [15:0] lfsr_a_stage1;
    reg [15:0] lfsr_b_stage1;

    // Stage 2: Output registers (pipeline stage 2, moved after retiming)
    reg [15:0] lfsr_a_stage2_output;
    reg [15:0] lfsr_b_stage2_output;

    // Combinational logic for LFSR feedback
    wire lfsr_a_feedback;
    wire lfsr_b_feedback;

    assign lfsr_a_feedback = lfsr_a_stage1[15] ^ lfsr_a_stage1[14] ^ lfsr_a_stage1[12] ^ lfsr_a_stage1[3];
    assign lfsr_b_feedback = lfsr_b_stage1[15] ^ lfsr_b_stage1[13] ^ lfsr_b_stage1[9]  ^ lfsr_b_stage1[2];

    // Pipeline: Stage 1 - LFSR state registers
    always @(posedge clk_a or posedge rst) begin
        if (rst)
            lfsr_a_stage1 <= 16'hACE1;
        else
            lfsr_a_stage1 <= {lfsr_a_stage1[14:0], lfsr_a_feedback};
    end

    always @(posedge clk_b or posedge rst) begin
        if (rst)
            lfsr_b_stage1 <= 16'h1CE2;
        else
            lfsr_b_stage1 <= {lfsr_b_stage1[14:0], lfsr_b_feedback};
    end

    // Pipeline: Stage 2 - Output registers (retimed from Stage 3 to here)
    always @(posedge clk_a or posedge rst) begin
        if (rst)
            lfsr_a_stage2_output <= 16'hACE1;
        else
            lfsr_a_stage2_output <= lfsr_a_stage1;
    end

    always @(posedge clk_b or posedge rst) begin
        if (rst)
            lfsr_b_stage2_output <= 16'h1CE2;
        else
            lfsr_b_stage2_output <= lfsr_b_stage1;
    end

    // Concatenate outputs from both LFSRs for the final random output
    assign random_out = {lfsr_a_stage2_output, lfsr_b_stage2_output};

endmodule