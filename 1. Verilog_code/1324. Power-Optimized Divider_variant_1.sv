//SystemVerilog
module power_opt_divider (
    input clock_i, nreset_i, enable_i,
    output clock_o
);
    reg [2:0] div_cnt;
    reg div_out;
    wire cnt_done;
    wire [2:0] next_cnt;
    
    // 为高扇出信号添加缓冲寄存器
    reg [2:0] div_cnt_buf1, div_cnt_buf2;
    reg div_out_buf1, div_out_buf2;
    reg cnt_done_buf1, cnt_done_buf2;
    reg [2:0] next_cnt_buf1, next_cnt_buf2;
    
    // 分配缓冲寄存器更新逻辑
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt_buf1 <= 3'b000;
            div_cnt_buf2 <= 3'b000;
            div_out_buf1 <= 1'b0;
            div_out_buf2 <= 1'b0;
            cnt_done_buf1 <= 1'b0;
            cnt_done_buf2 <= 1'b0;
            next_cnt_buf1 <= 3'b000;
            next_cnt_buf2 <= 3'b000;
        end else begin
            div_cnt_buf1 <= div_cnt;
            div_cnt_buf2 <= div_cnt;
            div_out_buf1 <= div_out;
            div_out_buf2 <= div_out;
            cnt_done_buf1 <= cnt_done;
            cnt_done_buf2 <= cnt_done;
            next_cnt_buf1 <= next_cnt;
            next_cnt_buf2 <= next_cnt;
        end
    end
    
    assign cnt_done = (div_cnt_buf1 == 3'b111);
    
    // Brent-Kung加法器实现：3位加法器
    // 生成信号(Generate)
    wire [2:0] g;
    // 为高扇出信号g添加缓冲
    reg [2:0] g_buf1, g_buf2;
    
    // 传播信号(Propagate)
    wire [2:0] p;
    // 进位信号(Carry)
    wire [3:0] c;
    
    // 第一阶段：计算初始的生成和传播信号
    assign g[0] = div_cnt_buf1[0] & 1'b1; // 与1相加的位生成
    assign g[1] = div_cnt_buf1[1] & 1'b0;
    assign g[2] = div_cnt_buf1[2] & 1'b0;
    
    // 为g信号添加缓冲寄存器
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            g_buf1 <= 3'b000;
            g_buf2 <= 3'b000;
        end else begin
            g_buf1 <= g;
            g_buf2 <= g;
        end
    end
    
    assign p[0] = div_cnt_buf2[0] ^ 1'b1; // 与1相加的位传播
    assign p[1] = div_cnt_buf2[1] ^ 1'b0;
    assign p[2] = div_cnt_buf2[2] ^ 1'b0;
    
    // 第二阶段：计算进位信号 - 使用缓冲的g信号减少扇出负载
    assign c[0] = 1'b0; // 初始进位为0
    assign c[1] = g_buf1[0] | (p[0] & c[0]);
    assign c[2] = g_buf1[1] | (p[1] & c[1]);
    assign c[3] = g_buf1[2] | (p[2] & c[2]);
    
    // 第三阶段：计算结果
    assign next_cnt[0] = p[0] ^ c[0];
    assign next_cnt[1] = p[1] ^ c[1];
    assign next_cnt[2] = p[2] ^ c[2];
    
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt <= 3'b000;
            div_out <= 1'b0;
        end else if (enable_i) begin
            div_cnt <= cnt_done_buf1 ? 3'b000 : next_cnt_buf1;
            div_out <= cnt_done_buf2 ? ~div_out_buf1 : div_out_buf1;
        end
    end
    
    // 使用缓冲的div_out减少扇出
    assign clock_o = div_out_buf2 & enable_i;
endmodule