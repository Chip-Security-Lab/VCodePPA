//SystemVerilog
module scan_divider (
    input clk, rst_n, scan_en, scan_in,
    output reg clk_div,
    output scan_out
);
    // 全局时钟缓冲
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 扇出缓冲 - 时钟树
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // 扇出缓冲 - scan_en信号
    reg scan_en_buf1, scan_en_buf2, scan_en_buf3;
    
    // 将计数器逻辑分成多个流水线级
    reg [2:0] counter_stage1;
    reg [2:0] counter_stage1_buf1, counter_stage1_buf2;
    reg [2:0] counter_stage2;
    reg counter_at_max_stage1;
    reg counter_at_max_stage2;
    reg increment_needed_stage1;
    reg scan_shift_needed_stage1;
    reg scan_data_stage1;
    
    // scan_en_buf1缓冲逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            scan_en_buf1 <= 1'b0;
        else
            scan_en_buf1 <= scan_en;
    end
    
    // scan_en_buf2缓冲逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            scan_en_buf2 <= 1'b0;
        else
            scan_en_buf2 <= scan_en;
    end
    
    // scan_en_buf3缓冲逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            scan_en_buf3 <= 1'b0;
        else
            scan_en_buf3 <= scan_en;
    end
    
    // increment_needed_stage1控制逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            increment_needed_stage1 <= 1'b0;
        else
            increment_needed_stage1 <= ~scan_en_buf1 & (counter_stage1 != 3'b111);
    end
    
    // scan_shift_needed_stage1控制逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            scan_shift_needed_stage1 <= 1'b0;
        else
            scan_shift_needed_stage1 <= scan_en_buf1;
    end
    
    // counter_at_max_stage1控制逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            counter_at_max_stage1 <= 1'b0;
        else
            counter_at_max_stage1 <= (counter_stage1 == 3'b111) & ~scan_en_buf1;
    end
    
    // scan_data_stage1采样逻辑
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            scan_data_stage1 <= 1'b0;
        else
            scan_data_stage1 <= scan_in;
    end
    
    // counter_stage1_buf1缓冲逻辑
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_stage1_buf1 <= 3'b000;
        else
            counter_stage1_buf1 <= counter_stage1;
    end
    
    // counter_stage1_buf2缓冲逻辑
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_stage1_buf2 <= 3'b000;
        else
            counter_stage1_buf2 <= counter_stage1;
    end
    
    // counter_stage1更新逻辑 - 扫描模式
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_stage1 <= 3'b000;
        else if (scan_shift_needed_stage1)
            counter_stage1 <= {counter_stage1_buf1[1:0], scan_data_stage1};
        else if (counter_at_max_stage1)
            counter_stage1 <= 3'b000;
        else if (increment_needed_stage1)
            counter_stage1 <= counter_stage1_buf1 + 1'b1;
    end
    
    // counter_stage2更新逻辑
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_stage2 <= 3'b000;
        else
            counter_stage2 <= counter_stage1_buf2;
    end
    
    // counter_at_max_stage2更新逻辑
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            counter_at_max_stage2 <= 1'b0;
        else
            counter_at_max_stage2 <= counter_at_max_stage1;
    end
    
    // b0_buf缓冲逻辑 (scan_out输出驱动)
    reg b0_buf;
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n)
            b0_buf <= 1'b0;
        else
            b0_buf <= counter_stage2[2];
    end
    
    // 时钟分频输出逻辑
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 1'b0;
        else if (counter_at_max_stage2)
            clk_div <= ~clk_div;
    end
    
    // 扫描输出连接到缓冲的b0信号
    assign scan_out = b0_buf;
endmodule