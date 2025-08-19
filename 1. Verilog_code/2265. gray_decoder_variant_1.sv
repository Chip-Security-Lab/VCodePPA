//SystemVerilog
// Top level module
module gray_decoder #(
    parameter WIDTH = 8  // 更改为8位宽度以符合要求
)(
    input [WIDTH-1:0] gray_in,
    output [WIDTH-1:0] binary_out
);
    // 使用基于并行前缀结构的gray decoder
    parallel_prefix_gray_decoder #(
        .WIDTH(WIDTH)
    ) parallel_prefix_inst (
        .gray_code(gray_in),
        .binary_code(binary_out)
    );
endmodule

// 基于并行前缀结构的gray decoder模块
module parallel_prefix_gray_decoder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] gray_code,
    output [WIDTH-1:0] binary_code
);
    // 使用并行前缀结构实现Gray码转二进制
    // 定义中间信号
    wire [WIDTH-1:0] level_0;
    wire [WIDTH-1:0] level_1;
    wire [WIDTH-1:0] level_2;
    
    // 初始化第一级 - 拷贝输入
    assign level_0 = gray_code;
    
    // 并行前缀级联 - 对数复杂度实现
    // 第一级转换
    genvar i;
    generate
        // 最高位直接传递
        assign binary_code[WIDTH-1] = level_0[WIDTH-1];
        
        // 第一级级联
        for(i = 0; i < WIDTH-1; i = i + 1) begin : level1_gen
            // 第一级生成逻辑
            if(i < WIDTH-2) begin
                assign level_1[i] = level_0[i] ^ level_0[i+1];
            end else begin
                assign level_1[i] = level_0[i];
            end
        end
        
        // 第二级级联
        for(i = 0; i < WIDTH-1; i = i + 1) begin : level2_gen
            // 第二级生成逻辑
            if(i < WIDTH-4) begin
                assign level_2[i] = level_1[i] ^ level_1[i+2];
            end else begin
                assign level_2[i] = level_1[i];
            end
        end
        
        // 最终级联并输出结果
        for(i = 0; i < WIDTH-1; i = i + 1) begin : final_stage
            // 最终结果计算 - 根据位置使用不同级联结果
            if(i < WIDTH-4) begin
                assign binary_code[i] = level_2[i] ^ binary_code[WIDTH-1];
            end else if(i < WIDTH-2) begin
                assign binary_code[i] = level_1[i] ^ binary_code[WIDTH-1];
            end else begin
                assign binary_code[i] = level_0[i] ^ binary_code[WIDTH-1];
            end
        end
    endgenerate
endmodule

// 并行前缀减法器子模块
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    // 加法器信号定义
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] b_comp;
    
    // 取反b
    assign b_comp = ~b;
    
    // 设置初始进位为1（用于二进制补码）
    assign carry[0] = 1'b1;
    
    // 并行前缀逻辑
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    
    // 第一级 - 基本生成和传播
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : pp_stage0
            assign p[i] = a[i] | b_comp[i];
            assign g[i] = a[i] & b_comp[i];
        end
    endgenerate
    
    // 第二级 - 合并传播信号（对数级联）
    wire [WIDTH-1:0] pp_level1_g;
    wire [WIDTH-1:0] pp_level1_p;
    
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : pp_stage1
            if(i == 0) begin
                assign pp_level1_g[i] = g[i];
                assign pp_level1_p[i] = p[i];
            end else begin
                assign pp_level1_g[i] = g[i] | (p[i] & g[i-1]);
                assign pp_level1_p[i] = p[i] & p[i-1];
            end
        end
    endgenerate
    
    // 第三级 - 继续合并（对数级联）
    wire [WIDTH-1:0] pp_level2_g;
    wire [WIDTH-1:0] pp_level2_p;
    
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : pp_stage2
            if(i < 2) begin
                assign pp_level2_g[i] = pp_level1_g[i];
                assign pp_level2_p[i] = pp_level1_p[i];
            end else begin
                assign pp_level2_g[i] = pp_level1_g[i] | (pp_level1_p[i] & pp_level1_g[i-2]);
                assign pp_level2_p[i] = pp_level1_p[i] & pp_level1_p[i-2];
            end
        end
    endgenerate
    
    // 级联传播以生成进位
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    // 最终计算差值
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : diff_gen
            assign diff[i] = a[i] ^ b_comp[i] ^ carry[i];
        end
    endgenerate
endmodule