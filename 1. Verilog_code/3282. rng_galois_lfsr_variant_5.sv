//SystemVerilog
// rng_galois_lfsr_2_top: Top-level module for hierarchical Galois LFSR RNG with deeper pipeline
module rng_galois_lfsr_2_top(
    input             clk,
    input             rst_n,
    input             enable,
    output [15:0]     data_out
);

    // Internal pipeline signals
    wire [15:0] state_stage1_out;
    wire        valid_stage1_out;
    wire        enable_stage1_out;

    wire [15:0] state_stage2_out;
    wire        valid_stage2_out;
    wire        enable_stage2_out;

    wire [15:0] state_stage3_out;
    wire        valid_stage3_out;
    wire        enable_stage3_out;

    wire [15:0] state_stage4_out;
    wire        valid_stage4_out;
    wire        enable_stage4_out;

    // Stage 1: Latch previous state and prepare for bit[15] computation
    lfsr_stage1 u_lfsr_stage1 (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .prev_state    (state_stage4_out),
        .state_stage1_out     (state_stage1_out),
        .valid_stage1_out     (valid_stage1_out),
        .enable_stage1_out    (enable_stage1_out)
    );

    // Stage 2: Calculate bit[0] and bit[1]
    lfsr_stage2 u_lfsr_stage2 (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_stage1_in      (valid_stage1_out),
        .enable_stage1_in     (enable_stage1_out),
        .state_stage1_in      (state_stage1_out),
        .state_stage2_out     (state_stage2_out),
        .valid_stage2_out     (valid_stage2_out),
        .enable_stage2_out    (enable_stage2_out)
    );

    // Stage 3: Calculate bit[2] and bit[3]
    lfsr_stage3 u_lfsr_stage3 (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_stage2_in      (valid_stage2_out),
        .enable_stage2_in     (enable_stage2_out),
        .state_stage2_in      (state_stage2_out),
        .state_stage3_out     (state_stage3_out),
        .valid_stage3_out     (valid_stage3_out),
        .enable_stage3_out    (enable_stage3_out)
    );

    // Stage 4: Shift remaining bits [15:4]
    lfsr_stage4 u_lfsr_stage4 (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_stage3_in      (valid_stage3_out),
        .enable_stage3_in     (enable_stage3_out),
        .state_stage3_in      (state_stage3_out),
        .state_stage4_out     (state_stage4_out),
        .valid_stage4_out     (valid_stage4_out),
        .enable_stage4_out    (enable_stage4_out)
    );

    // Output Stage: Latch output data
    lfsr_output_stage u_lfsr_output_stage (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in      (valid_stage4_out),
        .state_in      (state_stage4_out),
        .data_out      (data_out)
    );

endmodule

// lfsr_stage1: First pipeline stage for Galois LFSR
// - Latches state, passes to next stage
module lfsr_stage1(
    input             clk,
    input             rst_n,
    input             enable,
    input  [15:0]     prev_state,
    output reg [15:0] state_stage1_out,
    output reg        valid_stage1_out,
    output reg        enable_stage1_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage1_out   <= 16'hACE1;
            valid_stage1_out   <= 1'b0;
            enable_stage1_out  <= 1'b0;
        end else begin
            if(enable) begin
                state_stage1_out  <= prev_state;
                valid_stage1_out  <= 1'b1;
                enable_stage1_out <= enable;
            end else begin
                valid_stage1_out  <= 1'b0;
                enable_stage1_out <= 1'b0;
            end
        end
    end
endmodule

// lfsr_stage2: Second pipeline stage for Galois LFSR
// - Calculates next_state[0], next_state[1]
module lfsr_stage2(
    input             clk,
    input             rst_n,
    input             valid_stage1_in,
    input             enable_stage1_in,
    input  [15:0]     state_stage1_in,
    output reg [15:0] state_stage2_out,
    output reg        valid_stage2_out,
    output reg        enable_stage2_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage2_out   <= 16'hACE1;
            valid_stage2_out   <= 1'b0;
            enable_stage2_out  <= 1'b0;
        end else begin
            if(valid_stage1_in) begin
                state_stage2_out          <= state_stage1_in;
                // Calculate next_state[0] and next_state[1]
                state_stage2_out[0]       <= state_stage1_in[15];
                state_stage2_out[1]       <= state_stage1_in[0] ^ state_stage1_in[15];
                valid_stage2_out          <= 1'b1;
                enable_stage2_out         <= enable_stage1_in;
            end else begin
                valid_stage2_out          <= 1'b0;
                enable_stage2_out         <= 1'b0;
            end
        end
    end
endmodule

// lfsr_stage3: Third pipeline stage for Galois LFSR
// - Calculates next_state[2], next_state[3]
module lfsr_stage3(
    input             clk,
    input             rst_n,
    input             valid_stage2_in,
    input             enable_stage2_in,
    input  [15:0]     state_stage2_in,
    output reg [15:0] state_stage3_out,
    output reg        valid_stage3_out,
    output reg        enable_stage3_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage3_out   <= 16'hACE1;
            valid_stage3_out   <= 1'b0;
            enable_stage3_out  <= 1'b0;
        end else begin
            if(valid_stage2_in) begin
                state_stage3_out          <= state_stage2_in;
                // Calculate next_state[2] and next_state[3]
                state_stage3_out[2]       <= state_stage2_in[1];
                state_stage3_out[3]       <= state_stage2_in[2] ^ state_stage2_in[15];
                valid_stage3_out          <= 1'b1;
                enable_stage3_out         <= enable_stage2_in;
            end else begin
                valid_stage3_out          <= 1'b0;
                enable_stage3_out         <= 1'b0;
            end
        end
    end
endmodule

// lfsr_stage4: Fourth pipeline stage for Galois LFSR
// - Shifts next_state[15:4]
module lfsr_stage4(
    input             clk,
    input             rst_n,
    input             valid_stage3_in,
    input             enable_stage3_in,
    input  [15:0]     state_stage3_in,
    output reg [15:0] state_stage4_out,
    output reg        valid_stage4_out,
    output reg        enable_stage4_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_stage4_out   <= 16'hACE1;
            valid_stage4_out   <= 1'b0;
            enable_stage4_out  <= 1'b0;
        end else begin
            if(valid_stage3_in) begin
                state_stage4_out           <= state_stage3_in;
                // Shift next_state[15:4]
                state_stage4_out[15:4]     <= state_stage3_in[14:3];
                valid_stage4_out           <= 1'b1;
                enable_stage4_out          <= enable_stage3_in;
            end else begin
                valid_stage4_out           <= 1'b0;
                enable_stage4_out          <= 1'b0;
            end
        end
    end
endmodule

// lfsr_output_stage: Output register stage for Galois LFSR
// - Latches output data when valid
module lfsr_output_stage(
    input             clk,
    input             rst_n,
    input             valid_in,
    input  [15:0]     state_in,
    output reg [15:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= 16'hACE1;
        end else if(valid_in) begin
            data_out <= state_in;
        end
    end
endmodule