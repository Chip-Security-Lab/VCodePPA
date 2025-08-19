//SystemVerilog
module Comparator_GrayCode #(
    parameter WIDTH = 4,
    parameter THRESHOLD = 1      // 允许差异位数
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output             is_adjacent  
);
    // 格雷码差异检测
    wire [WIDTH-1:0] xor_result = gray_code_a ^ gray_code_b;
    
    // 使用先行进位加法器计算汉明距离
    wire [WIDTH:0] pop_count;
    
    // 生成信号
    wire [WIDTH-1:0] g;
    // 传播信号
    wire [WIDTH-1:0] p;
    
    // 中间进位信号
    wire [WIDTH:0] c;
    
    // 初始条件
    assign c[0] = 1'b0;
    
    // 设置生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = 1'b0;               // 加法中没有进位生成
            assign p[i] = xor_result[i];      // 传播取决于是否有差异位
            
            // 先行进位逻辑
            assign c[i+1] = g[i] | (p[i] & c[i]);
            
            // 计算每位的和
            assign pop_count[i] = p[i] ^ c[i];
        end
    endgenerate
    
    // 最高位进位作为最高位结果
    assign pop_count[WIDTH] = c[WIDTH];
    
    // 比较与阈值
    assign is_adjacent = (pop_count <= THRESHOLD);
endmodule