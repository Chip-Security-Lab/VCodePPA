//SystemVerilog
module multi_bit_lfsr (
    input clk,
    input rst,
    output [19:0] rnd_out
);

    // Main LFSR register and pipeline stages
    reg [19:0] lfsr_stage1;
    reg [19:0] lfsr_stage2;
    reg [19:0] lfsr_stage3;
    reg [19:0] lfsr_stage4;
    reg [19:0] lfsr_stage5;

    // Buffer registers for high fanout LFSR stages
    reg [19:0] lfsr_stage1_buf1, lfsr_stage1_buf2;
    reg [19:0] lfsr_stage2_buf1, lfsr_stage2_buf2;
    reg [19:0] lfsr_stage3_buf1, lfsr_stage3_buf2;
    reg [19:0] lfsr_stage4_buf1, lfsr_stage4_buf2;
    reg [19:0] lfsr_stage5_buf1, lfsr_stage5_buf2;

    // Tap calculation pipeline stages
    reg [19:0] lfsr_tap_stage1;
    reg [19:0] lfsr_tap_stage2;
    reg [19:0] lfsr_tap_stage3;
    reg [3:0]  taps_stage1;
    reg [3:0]  taps_stage2;
    reg [3:0]  taps_stage3;

    // Intermediate tap wires for splitting tap logic
    wire tap0_stage1, tap0_stage2;
    wire tap1_stage1, tap1_stage2;
    wire tap2_stage1, tap2_stage2;
    wire tap3_stage1, tap3_stage2;

    // 1st stage of tap calculation using buffered LFSR stage
    assign tap0_stage1 = lfsr_tap_stage2[19] ^ lfsr_tap_stage2[16];
    assign tap1_stage1 = lfsr_tap_stage2[15] ^ lfsr_tap_stage2[12];
    assign tap2_stage1 = lfsr_tap_stage2[11] ^ lfsr_tap_stage2[8];
    assign tap3_stage1 = lfsr_tap_stage2[7]  ^ lfsr_tap_stage2[0];

    // 2nd stage of tap calculation (buffering)
    assign tap0_stage2 = tap0_stage1;
    assign tap1_stage2 = tap1_stage1;
    assign tap2_stage2 = tap2_stage1;
    assign tap3_stage2 = tap3_stage1;

    always @(posedge clk) begin
        if (rst) begin
            // Initialize all pipeline stages, buffers, and taps
            lfsr_stage1      <= 20'hFACEB;
            lfsr_stage2      <= 20'hFACEB;
            lfsr_stage3      <= 20'hFACEB;
            lfsr_stage4      <= 20'hFACEB;
            lfsr_stage5      <= 20'hFACEB;

            lfsr_stage1_buf1 <= 20'hFACEB;
            lfsr_stage1_buf2 <= 20'hFACEB;
            lfsr_stage2_buf1 <= 20'hFACEB;
            lfsr_stage2_buf2 <= 20'hFACEB;
            lfsr_stage3_buf1 <= 20'hFACEB;
            lfsr_stage3_buf2 <= 20'hFACEB;
            lfsr_stage4_buf1 <= 20'hFACEB;
            lfsr_stage4_buf2 <= 20'hFACEB;
            lfsr_stage5_buf1 <= 20'hFACEB;
            lfsr_stage5_buf2 <= 20'hFACEB;

            lfsr_tap_stage1  <= 20'hFACEB;
            lfsr_tap_stage2  <= 20'hFACEB;
            lfsr_tap_stage3  <= 20'hFACEB;
            taps_stage1      <= 4'b0;
            taps_stage2      <= 4'b0;
            taps_stage3      <= 4'b0;
        end else begin
            // LFSR main pipeline
            lfsr_stage1      <= {lfsr_stage5_buf2[15:0], taps_stage3};
            lfsr_stage2      <= lfsr_stage1_buf2;
            lfsr_stage3      <= lfsr_stage2_buf2;
            lfsr_stage4      <= lfsr_stage3_buf2;
            lfsr_stage5      <= lfsr_stage4_buf2;

            // Buffering for high fanout signals
            lfsr_stage1_buf1 <= lfsr_stage1;
            lfsr_stage1_buf2 <= lfsr_stage1_buf1;
            lfsr_stage2_buf1 <= lfsr_stage2;
            lfsr_stage2_buf2 <= lfsr_stage2_buf1;
            lfsr_stage3_buf1 <= lfsr_stage3;
            lfsr_stage3_buf2 <= lfsr_stage3_buf1;
            lfsr_stage4_buf1 <= lfsr_stage4;
            lfsr_stage4_buf2 <= lfsr_stage4_buf1;
            lfsr_stage5_buf1 <= lfsr_stage5;
            lfsr_stage5_buf2 <= lfsr_stage5_buf1;

            // Pipeline for tap calculation using buffered LFSR stage
            lfsr_tap_stage1  <= lfsr_stage4_buf2;
            lfsr_tap_stage2  <= lfsr_tap_stage1;
            lfsr_tap_stage3  <= lfsr_tap_stage2;

            // Tap calculation pipeline
            taps_stage1      <= {tap3_stage1, tap2_stage1, tap1_stage1, tap0_stage1};
            taps_stage2      <= taps_stage1;
            taps_stage3      <= taps_stage2;
        end
    end

    // Output from the last LFSR pipeline stage buffer
    assign rnd_out = lfsr_stage5_buf2;

endmodule