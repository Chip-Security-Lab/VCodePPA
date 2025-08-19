//SystemVerilog
module rng_async_mix_7(
    input      [7:0] in_cnt,
    output     [7:0] out_rand
);
    // Pipeline Stage 1: Extract and operate on input fields
    wire [3:0] lower_nibble_stage1;
    wire [3:0] upper_nibble_stage1;
    wire [1:0] lower2_stage1;
    wire [1:0] mid2_stage1;
    wire [1:0] upper2_stage1;

    assign lower_nibble_stage1 = in_cnt[3:0];
    assign upper_nibble_stage1 = in_cnt[7:4];
    assign lower2_stage1       = in_cnt[1:0];
    assign mid2_stage1         = in_cnt[3:2];
    assign upper2_stage1       = in_cnt[5:4];

    // Pipeline Stage 2: Register outputs of Stage 1
    reg [3:0] lower_nibble_stage2;
    reg [3:0] upper_nibble_stage2;
    reg [1:0] lower2_stage2;
    reg [1:0] mid2_stage2;
    reg [1:0] upper2_stage2;

    always @(*) begin
        lower_nibble_stage2 = lower_nibble_stage1;
        upper_nibble_stage2 = upper_nibble_stage1;
        lower2_stage2       = lower2_stage1;
        mid2_stage2         = mid2_stage1;
        upper2_stage2       = upper2_stage1;
    end

    // Pipeline Stage 3: Main arithmetic/logic operations
    wire [3:0] xor_nibble_stage3;
    wire [1:0] sum_lower_mid_stage3;
    wire [1:0] xor_rand_stage3;

    assign xor_nibble_stage3      = lower_nibble_stage2 ^ upper_nibble_stage2;
    assign sum_lower_mid_stage3   = lower2_stage2 + mid2_stage2;
    assign xor_rand_stage3        = sum_lower_mid_stage3 ^ upper2_stage2;

    // Pipeline Stage 4: Register outputs of Stage 3
    reg [3:0] xor_nibble_stage4;
    reg [1:0] xor_rand_stage4;

    always @(*) begin
        xor_nibble_stage4 = xor_nibble_stage3;
        xor_rand_stage4   = xor_rand_stage3;
    end

    // Output assembly
    assign out_rand = {xor_nibble_stage4, 2'b00, xor_rand_stage4};

endmodule