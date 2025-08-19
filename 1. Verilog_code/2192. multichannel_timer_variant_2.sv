//SystemVerilog
module multichannel_timer #(
    parameter CHANNELS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [CHANNELS-1:0] channel_en,
    input wire [DATA_WIDTH-1:0] timeout_values [CHANNELS-1:0],
    output reg [CHANNELS-1:0] timeout_flags,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    // 将高扇出常量参数缓存为本地参数
    localparam CHANNEL_BITS = $clog2(CHANNELS);
    
    // 分组输入寄存器以减少扇出
    reg [CHANNELS-1:0] channel_en_reg;
    // 为高扇出信号添加缓冲区
    reg [CHANNELS-1:0] channel_en_buf1, channel_en_buf2;
    
    // 将timeout_values寄存器分成多组，减少扇出
    reg [DATA_WIDTH-1:0] timeout_values_reg [CHANNELS-1:0];
    reg [DATA_WIDTH-1:0] timeout_values_buf1 [CHANNELS-1:0];
    reg [DATA_WIDTH-1:0] timeout_values_buf2 [CHANNELS-1:0];
    
    // 计数器和比较器的分离，用于前向寄存器重定时
    reg [DATA_WIDTH-1:0] counters [CHANNELS-1:0];
    reg [DATA_WIDTH-1:0] counters_buf1 [CHANNELS/2-1:0];
    reg [DATA_WIDTH-1:0] counters_buf2 [CHANNELS/2-1:0];
    
    wire [DATA_WIDTH-1:0] counter_next [CHANNELS-1:0];
    wire [CHANNELS-1:0] timeout_cmp;
    reg [CHANNELS-1:0] timeout_cmp_reg;
    
    // 创建索引缓冲寄存器，减少i变量的扇出
    reg [CHANNEL_BITS-1:0] i_index_buf1, i_index_buf2;
    
    integer i;
    
    // 为每个通道实例化并行前缀加法器
    genvar g;
    generate
        for (g = 0; g < CHANNELS; g = g + 1) begin : gen_adders
            kogge_stone_adder #(
                .WIDTH(DATA_WIDTH)
            ) adder_inst (
                .a(g < CHANNELS/2 ? counters_buf1[g] : counters_buf2[g-CHANNELS/2]),
                .b(16'h0001),
                .cin(1'b0),
                .sum(counter_next[g]),
                .cout()
            );
            
            // 将比较器作为组合逻辑提前
            assign timeout_cmp[g] = (g < CHANNELS/2 ? 
                                   counters_buf1[g] >= timeout_values_buf1[g] : 
                                   counters_buf2[g-CHANNELS/2] >= timeout_values_buf2[g]);
        end
    endgenerate
    
    // 多级寄存输入信号，减少输入到第一级寄存器的扇出
    always @(posedge clock) begin
        if (reset) begin
            channel_en_reg <= {CHANNELS{1'b0}};
            channel_en_buf1 <= {CHANNELS{1'b0}};
            channel_en_buf2 <= {CHANNELS{1'b0}};
            
            for (i = 0; i < CHANNELS; i = i + 1) begin
                timeout_values_reg[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            channel_en_reg <= channel_en;
            channel_en_buf1 <= channel_en_reg;
            channel_en_buf2 <= channel_en_buf1;
            
            for (i = 0; i < CHANNELS; i = i + 1) begin
                timeout_values_reg[i] <= timeout_values[i];
            end
        end
    end
    
    // 添加timeout_values_reg的缓冲寄存器
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                timeout_values_buf1[i] <= {DATA_WIDTH{1'b0}};
                timeout_values_buf2[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                timeout_values_buf1[i] <= timeout_values_reg[i];
                timeout_values_buf2[i] <= timeout_values_buf1[i];
            end
        end
    end
    
    // 添加counters缓冲寄存器
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS/2; i = i + 1) begin
                counters_buf1[i] <= {DATA_WIDTH{1'b0}};
                counters_buf2[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < CHANNELS/2; i = i + 1) begin
                counters_buf1[i] <= counters[i];
                counters_buf2[i] <= counters[i+CHANNELS/2];
            end
        end
    end
    
    // 缓存比较器结果，减少组合逻辑延迟
    always @(posedge clock) begin
        if (reset) begin
            timeout_cmp_reg <= {CHANNELS{1'b0}};
            i_index_buf1 <= {CHANNEL_BITS{1'b0}};
            i_index_buf2 <= {CHANNEL_BITS{1'b0}};
        end else begin
            timeout_cmp_reg <= timeout_cmp;
            i_index_buf1 <= active_channel;
            i_index_buf2 <= i_index_buf1;
        end
    end
    
    // 主处理逻辑，利用已比较的结果
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters[i] <= {DATA_WIDTH{1'b0}};
            end
            timeout_flags <= {CHANNELS{1'b0}};
            active_channel <= {CHANNEL_BITS{1'b0}};
        end else begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (channel_en_buf2[i]) begin
                    if (timeout_cmp_reg[i]) begin
                        counters[i] <= {DATA_WIDTH{1'b0}};
                        timeout_flags[i] <= 1'b1;
                        active_channel <= i[CHANNEL_BITS-1:0];
                    end else begin
                        counters[i] <= counter_next[i];
                        timeout_flags[i] <= 1'b0;
                    end
                end
            end
        end
    end
endmodule

// Kogge-Stone 并行前缀加法器实现
module kogge_stone_adder #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // 局部参数替代高扇出的clog2函数
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 生成和传播信号
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_temp [(LOG2_WIDTH):0];
    wire [WIDTH-1:0] p_temp [(LOG2_WIDTH):0];
    
    // 初始生成和传播信号
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
    
    // 初始化第0级
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_level0
            assign g_temp[0][i] = g[i];
            assign p_temp[0][i] = p[i];
        end
    endgenerate
    
    // 计算所有级别的前缀和
    generate
        for (i = 1; i <= LOG2_WIDTH; i = i + 1) begin : gen_levels
            for (j = 0; j < WIDTH; j = j + 1) begin : gen_bits
                if (j >= (1 << (i-1))) begin
                    assign g_temp[i][j] = g_temp[i-1][j] | (p_temp[i-1][j] & g_temp[i-1][j-(1<<(i-1))]);
                    assign p_temp[i][j] = p_temp[i-1][j] & p_temp[i-1][j-(1<<(i-1))];
                end else begin
                    assign g_temp[i][j] = g_temp[i-1][j];
                    assign p_temp[i][j] = p_temp[i-1][j];
                end
            end
        end
    endgenerate
    
    // 输入进位处理
    wire [WIDTH:0] carries;
    assign carries[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carries
            assign carries[i+1] = g_temp[LOG2_WIDTH][i] | (p_temp[LOG2_WIDTH][i] & carries[0]);
        end
    endgenerate
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ carries[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = carries[WIDTH];
endmodule