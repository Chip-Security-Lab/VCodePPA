//SystemVerilog
module parameterized_type_comp #(
    parameter WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] inputs [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] max_idx,
    output reg valid,
    // Han-Carlson加法器接口
    input [7:0] adder_a,
    input [7:0] adder_b,
    output reg [7:0] adder_sum
);
    integer i;
    
    // Han-Carlson加法器信号
    wire [7:0] p; // 生成信号
    wire [7:0] g; // 传播信号
    wire [7:0] c; // 进位信号
    wire [7:0] sum; // 和信号
    
    // 第一阶段：生成传播信号p和生成信号g
    assign p = adder_a ^ adder_b;
    assign g = adder_a & adder_b;
    
    // 第二阶段：前缀树计算进位信号 (Han-Carlson加法器实现)
    // 预处理
    wire [7:0] pp, gg;
    assign pp[0] = p[0];
    assign gg[0] = g[0];
    
    // Han-Carlson特有的前缀计算 (偶数位)
    wire [7:0] p_even, g_even;
    assign p_even[0] = p[0];
    assign g_even[0] = g[0];
    
    genvar j;
    generate
        for (j = 2; j < 8; j = j + 2) begin : gen_even
            assign p_even[j/2] = p[j];
            assign g_even[j/2] = g[j];
        end
    endgenerate
    
    // 偶数位前缀计算
    wire [3:0] p_prefix_even, g_prefix_even;
    
    // 第一层
    assign p_prefix_even[0] = p_even[0];
    assign g_prefix_even[0] = g_even[0];
    
    generate
        for (j = 1; j < 4; j = j + 1) begin : prefix_even_l1
            assign p_prefix_even[j] = p_even[j] & p_even[j-1];
            assign g_prefix_even[j] = g_even[j] | (p_even[j] & g_even[j-1]);
        end
    endgenerate
    
    // 进位计算
    assign c[0] = 1'b0; // 初始进位为0
    
    // 偶数位进位
    generate
        for (j = 2; j < 8; j = j + 2) begin : carry_even
            assign c[j] = g_prefix_even[j/2-1];
        end
    endgenerate
    
    // 奇数位进位
    generate
        for (j = 1; j < 8; j = j + 2) begin : carry_odd
            assign c[j] = g[j-1] | (p[j-1] & c[j-1]);
        end
    endgenerate
    
    // 第三阶段：计算最终和
    assign sum = p ^ c;
    
    // 寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adder_sum <= 8'b0;
        end else begin
            adder_sum <= sum;
        end
    end
    
    // 原有的最大值索引查找逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_idx <= 0;
            valid <= 0;
        end else begin
            max_idx <= 0;
            valid <= 1;
            
            for (i = 1; i < WIDTH; i = i + 1)
                if (inputs[i] > inputs[max_idx])
                    max_idx <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule