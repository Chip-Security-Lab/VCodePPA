//SystemVerilog
module usb_clock_recovery(
    input wire dp_in,
    input wire dm_in,
    input wire ref_clk,
    input wire rst_n,
    output reg recovered_clk,
    output reg bit_locked
);
    reg [2:0] edge_detect;
    reg [7:0] edge_counter;
    reg [7:0] period_count;
    wire [7:0] period_count_plus_one;
    
    // Han-Carlson加法器实现
    han_carlson_adder #(
        .WIDTH(8)
    ) period_adder (
        .a(period_count),
        .b(8'd1),
        .cin(1'b0),
        .sum(period_count_plus_one),
        .cout()
    );
    
    // 边沿检测逻辑
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detect <= 3'b000;
        end else begin
            edge_detect <= {edge_detect[1:0], dp_in ^ dm_in};
        end
    end
    
    // 周期计数逻辑
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            period_count <= 8'd0;
        end else begin
            if (edge_detect[2:1] == 2'b01) begin  // Rising edge
                if (period_count > 8'd10) begin
                    period_count <= 8'd0;
                end else begin
                    period_count <= period_count_plus_one;
                end
            end else begin
                period_count <= period_count_plus_one;
                if (period_count >= 8'd24) begin
                    period_count <= 8'd0;
                end
            end
        end
    end
    
    // 时钟恢复逻辑
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_clk <= 1'b0;
        end else begin
            if (edge_detect[2:1] == 2'b01 && period_count > 8'd10) begin
                recovered_clk <= 1'b1;
            end else if (period_count >= 8'd24) begin
                recovered_clk <= 1'b0;
            end
        end
    end
    
    // 锁定状态控制逻辑
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_locked <= 1'b0;
            edge_counter <= 8'd0;
        end else begin
            if (edge_detect[2:1] == 2'b01 && period_count > 8'd10) begin
                bit_locked <= 1'b1;
            end
        end
    end
endmodule

// Han-Carlson并行前缀加法器 - 优化版本
module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // 缓冲高扇出参数信号
    reg [WIDTH-1:0] a_buf1, a_buf2;
    reg [WIDTH-1:0] b_buf1, b_buf2;
    reg [WIDTH/2-1:0] width_buf1, width_buf2;
    
    // 为高扇出参数添加缓冲寄存器
    always @(*) begin
        a_buf1 = a;
        a_buf2 = a;
        b_buf1 = b;
        b_buf2 = b;
        width_buf1 = WIDTH[WIDTH/2-1:0];
        width_buf2 = WIDTH[WIDTH-1:WIDTH/2];
    end
    
    // 定义内部信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH:0] c;   // 进位信号
    
    // 为高扇出p信号添加缓冲
    wire [WIDTH-1:0] p_buf1, p_buf2, p_buf3, p_buf4;
    
    // 阶段1: 生成基本传播和生成信号
    assign p = a_buf1 ^ b_buf1;
    assign g = a_buf2 & b_buf2;
    
    // 添加p信号缓冲
    assign p_buf1 = p;
    assign p_buf2 = p;
    assign p_buf3 = p;
    assign p_buf4 = p;
    
    // 进位输入连接
    assign c[0] = cin;
    
    // 阶段2: Han-Carlson并行前缀树 (拆分为奇数和偶数位)
    // 第一级: 处理奇数位
    wire [WIDTH-1:0] g_temp1, p_temp1;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin: stage1_even
            assign g_temp1[i] = g[i];
            assign p_temp1[i] = p_buf1[i];
        end
        
        for (i = 1; i < WIDTH; i = i + 2) begin: stage1_odd
            assign g_temp1[i] = g[i] | (p_buf2[i] & g[i-1]);
            assign p_temp1[i] = p_buf2[i] & p_buf1[i-1];
        end
    endgenerate
    
    // 添加g_temp1的缓冲寄存器，减少扇出负载
    wire [WIDTH-1:0] g_temp1_buf1, g_temp1_buf2;
    assign g_temp1_buf1 = g_temp1;
    assign g_temp1_buf2 = g_temp1;
    
    // 添加p_temp1的缓冲寄存器
    wire [WIDTH-1:0] p_temp1_buf1, p_temp1_buf2;
    assign p_temp1_buf1 = p_temp1;
    assign p_temp1_buf2 = p_temp1;
    
    // 第二级: 对偶数位进行组合操作
    wire [WIDTH-1:0] g_temp2, p_temp2;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: stage2
            if (i < 2) begin
                assign g_temp2[i] = g_temp1_buf1[i];
                assign p_temp2[i] = p_temp1_buf1[i];
            end
            else if (i % 2 == 0) begin
                assign g_temp2[i] = g_temp1_buf1[i] | (p_temp1_buf1[i] & g_temp1_buf2[i-2]);
                assign p_temp2[i] = p_temp1_buf1[i] & p_temp1_buf2[i-2];
            end
            else begin
                assign g_temp2[i] = g_temp1_buf2[i];
                assign p_temp2[i] = p_temp1_buf2[i];
            end
        end
    endgenerate
    
    // 添加g_temp2的缓冲寄存器
    wire [WIDTH-1:0] g_temp2_buf1, g_temp2_buf2;
    assign g_temp2_buf1 = g_temp2;
    assign g_temp2_buf2 = g_temp2;
    
    // 添加p_temp2的缓冲寄存器
    wire [WIDTH-1:0] p_temp2_buf1, p_temp2_buf2;
    assign p_temp2_buf1 = p_temp2;
    assign p_temp2_buf2 = p_temp2;
    
    // 第三级: 继续组合
    wire [WIDTH-1:0] g_temp3, p_temp3;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: stage3
            if (i < 4) begin
                assign g_temp3[i] = g_temp2_buf1[i];
                assign p_temp3[i] = p_temp2_buf1[i];
            end
            else if (i % 2 == 0) begin
                assign g_temp3[i] = g_temp2_buf1[i] | (p_temp2_buf1[i] & g_temp2_buf2[i-4]);
                assign p_temp3[i] = p_temp2_buf1[i] & p_temp2_buf2[i-4];
            end
            else begin
                assign g_temp3[i] = g_temp2_buf2[i];
                assign p_temp3[i] = p_temp2_buf2[i];
            end
        end
    endgenerate
    
    // 添加g_temp3的缓冲
    wire [WIDTH-1:0] g_temp3_buf;
    assign g_temp3_buf = g_temp3;
    
    // 添加p_temp3的缓冲
    wire [WIDTH-1:0] p_temp3_buf;
    assign p_temp3_buf = p_temp3;
    
    // 最终进位传播: 从偶数位传播到奇数位 - 使用缓冲信号
    wire [WIDTH-1:0] g_final;
    
    // 添加cin的缓冲寄存器，减少扇出
    wire cin_buf1, cin_buf2;
    assign cin_buf1 = cin;
    assign cin_buf2 = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: final_stage
            if (i == 0) begin
                assign c[i+1] = g[i] | (p_buf3[i] & cin_buf1);
            end
            else if (i % 2 == 0) begin
                assign c[i+1] = g_temp3_buf[i] | (p_temp3_buf[i] & cin_buf1);
            end
            else begin
                assign c[i+1] = g_temp3_buf[i] | (p_temp3_buf[i] & c[i]);
            end
        end
    endgenerate
    
    // 将进位信号分组进行缓冲
    wire [WIDTH/2-1:0] c_buf1;
    wire [WIDTH/2-1:0] c_buf2;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: carry_buf1
            assign c_buf1[i] = c[i];
        end
        for (i = 0; i < WIDTH/2; i = i + 1) begin: carry_buf2
            assign c_buf2[i] = c[i + WIDTH/2];
        end
    endgenerate
    
    // 计算最终输出 - 使用缓冲的p信号
    assign sum = p_buf4 ^ {c_buf2, c_buf1[WIDTH/2-1:0]};
    assign cout = c[WIDTH];
    
endmodule