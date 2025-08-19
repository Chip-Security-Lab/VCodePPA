//SystemVerilog
module tausworthe_rng_pipeline (
    input              clk_in,
    input              rst_in,
    input              start_in,
    input              flush_in,
    output reg         valid_out,
    output reg [31:0]  rnd_out
);

    // Buffered reset signal
    reg rst_buf1, rst_buf2;
    always @(posedge clk_in) begin
        rst_buf1 <= rst_in;
        rst_buf2 <= rst_buf1;
    end
    wire rst_sync = rst_buf2;

    // Stage 1: State registers, initialization, and stage1 valid
    reg  [31:0] s1_stage1, s2_stage1, s3_stage1;
    reg         valid_stage1;

    // Buffered stage 1 signals
    reg [31:0] s1_stage1_buf1, s2_stage1_buf1, s3_stage1_buf1;
    reg [31:0] s1_stage1_buf2, s2_stage1_buf2, s3_stage1_buf2;
    reg        valid_stage1_buf;

    // Stage 2: b calculation and stage2 valid
    reg  [31:0] s1_stage2, s2_stage2, s3_stage2;
    reg  [31:0] b1_stage2, b2_stage2, b3_stage2;
    reg         valid_stage2;

    // Buffered s1_stage2
    reg [31:0] s1_stage2_buf;

    // Stage 3: Next state calculation and stage3 valid
    reg  [31:0] s1_stage3, s2_stage3, s3_stage3;
    reg         valid_stage3;

    // Stage 4: Output calculation and valid
    reg  [31:0] rnd_out_stage4;
    reg         valid_stage4;

    // Stage 1: Latch initial or next state (buffered reset and buffer for high fanout signals)
    always @(posedge clk_in) begin
        if (rst_sync || flush_in) begin
            s1_stage1    <= 32'h1;
            s2_stage1    <= 32'h2;
            s3_stage1    <= 32'h4;
            valid_stage1 <= 1'b0;
        end else if (start_in || valid_stage3) begin
            if (start_in)
                valid_stage1 <= 1'b1;
            else
                valid_stage1 <= valid_stage3;
            if (valid_stage3) begin
                s1_stage1 <= s1_stage3;
                s2_stage1 <= s2_stage3;
                s3_stage1 <= s3_stage3;
            end
        end
    end

    // Buffering high fanout signals after stage1
    always @(posedge clk_in) begin
        s1_stage1_buf1 <= s1_stage1;
        s2_stage1_buf1 <= s2_stage1;
        s3_stage1_buf1 <= s3_stage1;
        valid_stage1_buf <= valid_stage1;
    end

    always @(posedge clk_in) begin
        s1_stage1_buf2 <= s1_stage1_buf1;
        s2_stage1_buf2 <= s2_stage1_buf1;
        s3_stage1_buf2 <= s3_stage1_buf1;
    end

    // Stage 2: Compute b1, b2, b3 (use buffered stage1 signals)
    always @(posedge clk_in) begin
        if (rst_sync || flush_in) begin
            b1_stage2     <= 32'b0;
            b2_stage2     <= 32'b0;
            b3_stage2     <= 32'b0;
            s1_stage2     <= 32'b0;
            s2_stage2     <= 32'b0;
            s3_stage2     <= 32'b0;
            valid_stage2  <= 1'b0;
        end else begin
            b1_stage2    <= (((s1_stage1_buf2 << 13) ^ s1_stage1_buf2) >> 19);
            b2_stage2    <= (((s2_stage1_buf2 << 2)  ^ s2_stage1_buf2) >> 25);
            b3_stage2    <= (((s3_stage1_buf2 << 3)  ^ s3_stage1_buf2) >> 11);
            s1_stage2    <= s1_stage1_buf2;
            s2_stage2    <= s2_stage1_buf2;
            s3_stage2    <= s3_stage1_buf2;
            valid_stage2 <= valid_stage1_buf;
        end
    end

    // Buffer s1_stage2 for high fanout
    always @(posedge clk_in) begin
        s1_stage2_buf <= s1_stage2;
    end

    // Stage 3: Calculate next state (use buffered s1_stage2)
    always @(posedge clk_in) begin
        if (rst_sync || flush_in) begin
            s1_stage3     <= 32'b0;
            s2_stage3     <= 32'b0;
            s3_stage3     <= 32'b0;
            valid_stage3  <= 1'b0;
        end else begin
            s1_stage3    <= (s1_stage2_buf & 32'hFFFFFFFE) ^ b1_stage2;
            s2_stage3    <= (s2_stage2 & 32'hFFFFFFF8) ^ b2_stage2;
            s3_stage3    <= (s3_stage2 & 32'hFFFFFFF0) ^ b3_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output calculation
    always @(posedge clk_in) begin
        if (rst_sync || flush_in) begin
            rnd_out_stage4 <= 32'b0;
            valid_stage4   <= 1'b0;
        end else begin
            rnd_out_stage4 <= s1_stage3 ^ s2_stage3 ^ s3_stage3;
            valid_stage4   <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk_in) begin
        if (rst_sync || flush_in) begin
            rnd_out   <= 32'b0;
            valid_out <= 1'b0;
        end else begin
            rnd_out   <= rnd_out_stage4;
            valid_out <= valid_stage4;
        end
    end

endmodule