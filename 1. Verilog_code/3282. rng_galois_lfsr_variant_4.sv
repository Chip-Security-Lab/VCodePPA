//SystemVerilog
// Top-level module: Hierarchical 16-bit Galois LFSR RNG (Pipelined)
module rng_galois_lfsr_2(
    input             clk,
    input             rst_n,
    input             enable,
    input             flush,
    output [15:0]     data_out,
    output            valid_out
);
    // Stage 1: LFSR State Register
    reg  [15:0] lfsr_state_stage1;
    reg         valid_stage1;
    wire [15:0] next_lfsr_state_stage1;
    wire        valid_in_stage1;

    // Stage 2: Next State Calculation
    reg  [15:0] next_lfsr_state_stage2;
    reg         valid_stage2;

    // Stage 3: Output Register
    reg  [15:0] data_out_stage3;
    reg         valid_stage3;

    // Valid input for stage1: enable && not flushing
    assign valid_in_stage1 = enable && !flush;

    // Stage 1: Capture current LFSR state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_stage1 <= 16'hACE1;
            valid_stage1      <= 1'b0;
        end else if (flush) begin
            lfsr_state_stage1 <= 16'hACE1;
            valid_stage1      <= 1'b0;
        end else if (valid_in_stage1) begin
            lfsr_state_stage1 <= next_lfsr_state_stage2; // feedback from Stage2
            valid_stage1      <= 1'b1;
        end else if (!valid_in_stage1) begin
            valid_stage1      <= 1'b0;
        end
    end

    // Stage 2: Next State Calculation (combinational -> registered)
    lfsr_next_state_16 u_lfsr_next_state_16 (
        .current_state(lfsr_state_stage1),
        .next_state(next_lfsr_state_stage1)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_lfsr_state_stage2 <= 16'hACE1;
            valid_stage2           <= 1'b0;
        end else if (flush) begin
            next_lfsr_state_stage2 <= 16'hACE1;
            valid_stage2           <= 1'b0;
        end else begin
            next_lfsr_state_stage2 <= next_lfsr_state_stage1;
            valid_stage2           <= valid_stage1;
        end
    end

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 16'hACE1;
            valid_stage3    <= 1'b0;
        end else if (flush) begin
            data_out_stage3 <= 16'hACE1;
            valid_stage3    <= 1'b0;
        end else begin
            data_out_stage3 <= lfsr_state_stage1;
            valid_stage3    <= valid_stage2;
        end
    end

    assign data_out  = data_out_stage3;
    assign valid_out = valid_stage3;

endmodule

// -------------------------------------------------------------------
// Submodule: lfsr_next_state_16
// Function: Computes next state for 16-bit Galois LFSR with taps at 16, 14, 13, 11 (as per original polynomial)
// -------------------------------------------------------------------
module lfsr_next_state_16(
    input  [15:0] current_state,
    output [15:0] next_state
);
    assign next_state[0]      = current_state[15];
    assign next_state[1]      = current_state[0] ^ current_state[15];
    assign next_state[2]      = current_state[1];
    assign next_state[3]      = current_state[2] ^ current_state[15];
    assign next_state[15:4]   = current_state[14:3];
endmodule