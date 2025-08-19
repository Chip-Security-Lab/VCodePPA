//SystemVerilog
module clock_enable_sync (
    input  wire        fast_clk,
    input  wire        slow_clk,
    input  wire        rst_n,
    input  wire        enable_src,
    output wire        enable_dst,
    input  wire        flush,           // 新增：流水线刷新信号
    input  wire        start            // 新增：流水线启动信号
);

    // Stage 1: 捕获slow_clk域的enable_src
    reg enable_src_ff_stage1;
    reg valid_stage1;
    // 扇出缓冲寄存器
    reg valid_stage1_buf1, valid_stage1_buf2;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_src_ff_stage1 <= 1'b0;
            valid_stage1         <= 1'b0;
        end else if (flush) begin
            enable_src_ff_stage1 <= 1'b0;
            valid_stage1         <= 1'b0;
        end else if (start) begin
            enable_src_ff_stage1 <= enable_src;
            valid_stage1         <= 1'b1;
        end
    end

    // valid_stage1 多级缓冲，减小扇出
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1_buf1 <= 1'b0;
            valid_stage1_buf2 <= 1'b0;
        end else if (flush) begin
            valid_stage1_buf1 <= 1'b0;
            valid_stage1_buf2 <= 1'b0;
        end else begin
            valid_stage1_buf1 <= valid_stage1;
            valid_stage1_buf2 <= valid_stage1_buf1;
        end
    end

    // Stage 2: fast_clk域，一级同步
    reg enable_meta_stage2;
    reg valid_stage2;
    // 扇出缓冲寄存器
    reg fast_clk_buf1, fast_clk_buf2;
    reg valid_stage2_buf1, valid_stage2_buf2;
    reg b0, b0_buf1, b0_buf2;

    // fast_clk 扇出缓冲（多级驱动）
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_clk_buf1 <= 1'b0;
            fast_clk_buf2 <= 1'b0;
        end else begin
            fast_clk_buf1 <= 1'b1;
            fast_clk_buf2 <= fast_clk_buf1;
        end
    end

    // valid_stage1缓冲后用于stage2
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_meta_stage2 <= 1'b0;
            valid_stage2       <= 1'b0;
            b0                 <= 1'b0;
        end else if (flush) begin
            enable_meta_stage2 <= 1'b0;
            valid_stage2       <= 1'b0;
            b0                 <= 1'b0;
        end else begin
            enable_meta_stage2 <= enable_src_ff_stage1;
            valid_stage2       <= valid_stage1_buf2;
            b0                 <= enable_src_ff_stage1; // b0高扇出缓冲
        end
    end

    // b0 多级缓冲
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else if (flush) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else begin
            b0_buf1 <= b0;
            b0_buf2 <= b0_buf1;
        end
    end

    // valid_stage2 多级缓冲
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2_buf1 <= 1'b0;
            valid_stage2_buf2 <= 1'b0;
        end else if (flush) begin
            valid_stage2_buf1 <= 1'b0;
            valid_stage2_buf2 <= 1'b0;
        end else begin
            valid_stage2_buf1 <= valid_stage2;
            valid_stage2_buf2 <= valid_stage2_buf1;
        end
    end

    // Stage 3: fast_clk域，二级同步
    reg enable_sync_stage3;
    reg valid_stage3;
    // 扇出缓冲寄存器
    reg valid_stage3_buf1, valid_stage3_buf2;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync_stage3 <= 1'b0;
            valid_stage3       <= 1'b0;
        end else if (flush) begin
            enable_sync_stage3 <= 1'b0;
            valid_stage3       <= 1'b0;
        end else begin
            enable_sync_stage3 <= enable_meta_stage2;
            valid_stage3       <= valid_stage2_buf2;
        end
    end

    // valid_stage3 多级缓冲
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3_buf1 <= 1'b0;
            valid_stage3_buf2 <= 1'b0;
        end else if (flush) begin
            valid_stage3_buf1 <= 1'b0;
            valid_stage3_buf2 <= 1'b0;
        end else begin
            valid_stage3_buf1 <= valid_stage3;
            valid_stage3_buf2 <= valid_stage3_buf1;
        end
    end

    // Stage 4: 输出寄存器
    reg enable_dst_stage4;
    reg valid_stage4;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_dst_stage4 <= 1'b0;
            valid_stage4      <= 1'b0;
        end else if (flush) begin
            enable_dst_stage4 <= 1'b0;
            valid_stage4      <= 1'b0;
        end else begin
            enable_dst_stage4 <= enable_sync_stage3;
            valid_stage4      <= valid_stage3_buf2;
        end
    end

    assign enable_dst = enable_dst_stage4 & valid_stage4;

endmodule