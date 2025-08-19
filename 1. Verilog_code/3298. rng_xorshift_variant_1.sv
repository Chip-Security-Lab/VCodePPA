//SystemVerilog
module rng_xorshift_18(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  data_o
);

    // ---------------- Pipeline Stage 0: State Register ----------------
    reg  [7:0] prng_state_stage0;   // PRNG state input to pipeline
    wire [7:0] prng_state_stage0_next;

    // ---------------- Pipeline Stage 1: XorShift << 3 ----------------
    reg  [7:0] prng_state_stage1;
    wire [7:0] prng_state_stage1_next;

    // ---------------- Pipeline Stage 2: XorShift >> 2 ----------------
    reg  [7:0] prng_state_stage2;
    wire [7:0] prng_state_stage2_next;

    // ---------------- Pipeline Stage 3: XorShift << 1 ----------------
    reg  [7:0] prng_state_stage3;
    wire [7:0] prng_state_stage3_next;

    // ---------------- Pipeline Stage 4: Output Register ----------------
    reg  [7:0] prng_state_stage4;

    // ---------------- Stage 0 Logic: State Update ----------------
    assign prng_state_stage0_next = (rst) ? 8'hAA : (en ? prng_state_stage4 : prng_state_stage0);

    always @(posedge clk) begin
        prng_state_stage0 <= prng_state_stage0_next;
    end

    // ---------------- Stage 1 Logic: XorShift << 3 ----------------
    assign prng_state_stage1_next = prng_state_stage0 ^ (prng_state_stage0 << 3);

    always @(posedge clk) begin
        if (rst)
            prng_state_stage1 <= 8'hAA;
        else if (en)
            prng_state_stage1 <= prng_state_stage1_next;
        else
            prng_state_stage1 <= prng_state_stage1;
    end

    // ---------------- Stage 2 Logic: XorShift >> 2 ----------------
    assign prng_state_stage2_next = prng_state_stage1 ^ (prng_state_stage1 >> 2);

    always @(posedge clk) begin
        if (rst)
            prng_state_stage2 <= 8'hAA;
        else if (en)
            prng_state_stage2 <= prng_state_stage2_next;
        else
            prng_state_stage2 <= prng_state_stage2;
    end

    // ---------------- Stage 3 Logic: XorShift << 1 ----------------
    assign prng_state_stage3_next = prng_state_stage2 ^ (prng_state_stage2 << 1);

    always @(posedge clk) begin
        if (rst)
            prng_state_stage3 <= 8'hAA;
        else if (en)
            prng_state_stage3 <= prng_state_stage3_next;
        else
            prng_state_stage3 <= prng_state_stage3;
    end

    // ---------------- Stage 4 Logic: Output Register ----------------
    always @(posedge clk) begin
        if (rst)
            prng_state_stage4 <= 8'hAA;
        else if (en)
            prng_state_stage4 <= prng_state_stage3;
        else
            prng_state_stage4 <= prng_state_stage4;
    end

    // ---------------- Output Assignment ----------------
    always @(posedge clk) begin
        if (rst)
            data_o <= 8'hAA;
        else
            data_o <= prng_state_stage0;
    end

endmodule