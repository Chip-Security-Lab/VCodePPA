//SystemVerilog
module gray_counter #(parameter WIDTH = 4) (
    input  wire              clk,
    input  wire              reset,
    input  wire              enable,
    output reg  [WIDTH-1:0]  gray_out
);
    // 注册pipeline各级数据
    reg  [WIDTH-1:0] binary_r;
    reg  [WIDTH-1:0] next_binary_r;
    wire [WIDTH-1:0] next_binary;
    wire [WIDTH-1:0] next_gray;
    
    // 二进制递增计算 - 使用并行前缀加法器
    parallel_prefix_adder #(
        .WIDTH(WIDTH)
    ) adder_inst (
        .a(binary_r),
        .b({{(WIDTH-1){1'b0}}, 1'b1}),
        .sum(next_binary)
    );
    
    // 格雷码转换逻辑 - 优化为寄存器输出
    assign next_gray = (next_binary_r >> 1) ^ next_binary_r;
    
    // 主状态更新逻辑
    always @(posedge clk) begin
        if (reset) begin
            binary_r     <= {WIDTH{1'b0}};
            next_binary_r <= {WIDTH{1'b0}};
            gray_out     <= {WIDTH{1'b0}};
        end 
        else if (enable) begin
            // 流水线第一级 - 计算二进制递增
            binary_r     <= binary_r;
            next_binary_r <= next_binary;
            
            // 流水线第二级 - 计算格雷码输出
            gray_out     <= next_gray;
        end
    end
endmodule

// 优化的并行前缀加法器
module parallel_prefix_adder #(parameter WIDTH = 4) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    // 内部信号定义
    wire [WIDTH-1:0] p_stage1;  // 传播信号
    wire [WIDTH-1:0] g_stage1;  // 生成信号
    wire [WIDTH:0]   c_stage2;  // 进位信号
    
    // 阶段1：计算初始传播和生成信号
    assign p_stage1 = a ^ b;  // 传播位
    assign g_stage1 = a & b;  // 生成位
    assign c_stage2[0] = 1'b0; // 初始进位
    
    // 阶段2：计算进位传播
    // 实现为并行前缀结构 - 按逻辑深度分层
    generate
        genvar i;
        
        // 第一层前缀树 - 计算每个位置的进位
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_layer1
            // 计算每位的进位
            assign c_stage2[i+1] = g_stage1[i] | (p_stage1[i] & c_stage2[i]);
        end
    endgenerate
    
    // 阶段3：计算最终和
    assign sum = p_stage1 ^ c_stage2[WIDTH-1:0];
endmodule