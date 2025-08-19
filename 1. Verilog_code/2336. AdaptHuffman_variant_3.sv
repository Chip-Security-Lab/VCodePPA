//SystemVerilog
module AdaptHuffman (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    reg [31:0] freq [0:255];
    integer i;

    // 初始化频率表
    initial begin
        for(i=0; i<256; i=i+1)
            freq[i] = 0;
    end

    // Han-Carlson加法器信号
    wire [31:0] a, b, sum;
    wire [31:0] p, g; // 传播和生成信号
    wire [31:0] pp, gg; // 预处理后的传播和生成信号
    
    // 加法器输入
    assign a = freq[data];
    assign b = 32'h1;

    // 第1阶段：预处理
    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin: pre_process
            assign p[j] = a[j] ^ b[j];
            assign g[j] = a[j] & b[j];
        end
    endgenerate

    // 关键路径流水线寄存器
    reg [31:0] p_stage1, g_stage1;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage1 <= 0;
        end
        else begin
            p_stage1 <= p;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage1 <= 0;
        end
        else begin
            g_stage1 <= g;
        end
    end

    // 第2阶段：前缀树计算
    // Han-Carlson算法 - 奇数位
    wire [31:0] g_odd_1, p_odd_1;
    wire [31:0] g_odd_2, p_odd_2;
    wire [31:0] g_odd_3, p_odd_3;
    wire [31:0] g_odd_4, p_odd_4;
    wire [31:0] g_odd_5, p_odd_5;

    // 初始奇数位选择
    generate
        for (j = 1; j < 32; j = j + 2) begin: odd_init
            assign g_odd_1[j] = g_stage1[j];
            assign p_odd_1[j] = p_stage1[j];
        end
    endgenerate

    // 并行前缀计算 - 奇数位
    generate
        for (j = 1; j < 32; j = j + 2) begin: odd_prefix_1
            if (j > 1) begin
                assign g_odd_2[j] = g_odd_1[j] | (p_odd_1[j] & g_odd_1[j-2]);
                assign p_odd_2[j] = p_odd_1[j] & p_odd_1[j-2];
            end
            else begin
                assign g_odd_2[j] = g_odd_1[j];
                assign p_odd_2[j] = p_odd_1[j];
            end
        end
    endgenerate

    // 关键路径中间流水线寄存器
    reg [31:0] g_odd_2_reg, p_odd_2_reg;
    
    // g_odd_2寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_odd_2_reg <= 0;
        end
        else begin
            g_odd_2_reg <= g_odd_2;
        end
    end
    
    // p_odd_2寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_odd_2_reg <= 0;
        end
        else begin
            p_odd_2_reg <= p_odd_2;
        end
    end

    generate
        for (j = 1; j < 32; j = j + 2) begin: odd_prefix_2
            if (j > 3) begin
                assign g_odd_3[j] = g_odd_2_reg[j] | (p_odd_2_reg[j] & g_odd_2_reg[j-4]);
                assign p_odd_3[j] = p_odd_2_reg[j] & p_odd_2_reg[j-4];
            end
            else begin
                assign g_odd_3[j] = g_odd_2_reg[j];
                assign p_odd_3[j] = p_odd_2_reg[j];
            end
        end
    endgenerate

    generate
        for (j = 1; j < 32; j = j + 2) begin: odd_prefix_3
            if (j > 7) begin
                assign g_odd_4[j] = g_odd_3[j] | (p_odd_3[j] & g_odd_3[j-8]);
                assign p_odd_4[j] = p_odd_3[j] & p_odd_3[j-8];
            end
            else begin
                assign g_odd_4[j] = g_odd_3[j];
                assign p_odd_4[j] = p_odd_3[j];
            end
        end
    endgenerate

    // 另一处关键路径流水线寄存器
    reg [31:0] g_odd_4_reg, p_odd_4_reg;
    
    // g_odd_4寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_odd_4_reg <= 0;
        end
        else begin
            g_odd_4_reg <= g_odd_4;
        end
    end
    
    // p_odd_4寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_odd_4_reg <= 0;
        end
        else begin
            p_odd_4_reg <= p_odd_4;
        end
    end

    generate
        for (j = 1; j < 32; j = j + 2) begin: odd_prefix_4
            if (j > 15) begin
                assign g_odd_5[j] = g_odd_4_reg[j] | (p_odd_4_reg[j] & g_odd_4_reg[j-16]);
                assign p_odd_5[j] = p_odd_4_reg[j] & p_odd_4_reg[j-16];
            end
            else begin
                assign g_odd_5[j] = g_odd_4_reg[j];
                assign p_odd_5[j] = p_odd_4_reg[j];
            end
        end
    endgenerate

    // 第3阶段：偶数位传播
    wire [31:0] g_even, p_even;

    // 初始设置
    assign g_even[0] = g_stage1[0];
    assign p_even[0] = p_stage1[0];

    generate
        for (j = 2; j < 32; j = j + 2) begin: even_process
            assign g_even[j] = g_stage1[j] | (p_stage1[j] & g_odd_5[j-1]);
            assign p_even[j] = p_stage1[j] & p_odd_5[j-1];
        end
    endgenerate

    // 第4阶段：计算进位
    wire [31:0] carry;
    assign carry[0] = g_stage1[0];

    generate
        for (j = 1; j < 32; j = j + 1) begin: carry_compute
            if (j % 2 == 1)
                assign carry[j] = g_odd_5[j];
            else
                assign carry[j] = g_even[j];
        end
    endgenerate

    // 第5阶段：求和
    reg [31:0] sum_reg;
    wire [31:0] sum_wire;
    
    generate
        for (j = 0; j < 32; j = j + 1) begin: sum_compute
            if (j == 0)
                assign sum_wire[j] = p_stage1[j];
            else
                assign sum_wire[j] = p_stage1[j] ^ carry[j-1];
        end
    endgenerate
    
    assign sum = sum_reg;

    // 最终流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 0;
        end
        else begin
            sum_reg <= sum_wire;
        end
    end

    // 数据输出和更新延迟控制 - 拆分为多个小型always块
    reg [7:0] data_d1, data_d2, data_d3, data_d4;
    
    // data_d1延迟寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_d1 <= 0;
        end
        else begin
            data_d1 <= data;
        end
    end
    
    // data_d2延迟寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_d2 <= 0;
        end
        else begin
            data_d2 <= data_d1;
        end
    end
    
    // data_d3延迟寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_d3 <= 0;
        end
        else begin
            data_d3 <= data_d2;
        end
    end
    
    // data_d4延迟寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_d4 <= 0;
        end
        else begin
            data_d4 <= data_d3;
        end
    end
    
    // code输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code <= 0;
        end
        else begin
            code <= sum[15:0];
        end
    end

    // 频率更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<256; i=i+1)
                freq[i] <= 0;
        end
        else begin
            freq[data_d4] <= sum;
        end
    end
endmodule