//SystemVerilog
module MaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, mask,
    output match
);
    wire [WIDTH-1:0] data_masked, pattern_masked;
    wire [WIDTH-1:0] difference;
    wire cout;
    
    assign data_masked = data & mask;
    assign pattern_masked = pattern & mask;
    
    // 使用并行前缀减法器计算 data_masked - pattern_masked
    ParallelPrefixSubtractor #(
        .WIDTH(WIDTH)
    ) subtractor (
        .a(data_masked),
        .b(pattern_masked),
        .difference(difference),
        .cout(cout)
    );
    
    // 当差值为0时，两个操作数相等
    assign match = (difference == {WIDTH{1'b0}});
endmodule

module ParallelPrefixSubtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] difference,
    output cout
);
    // 内部信号
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] propagate[WIDTH:0];
    wire [WIDTH:0] generate_bit[WIDTH:0];
    wire [WIDTH:0] carry;
    
    // 计算补码 (取反加一) 
    assign b_complement = ~b;
    
    // 初始进位为1，用于补码加法
    assign carry[0] = 1'b1;
    
    // 第一阶段：生成P和G信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign propagate[i] = a[i] ^ b_complement[i];
            assign generate_bit[i] = a[i] & b_complement[i];
        end
    endgenerate
    
    // 第二阶段：并行前缀计算进位
    // 使用Kogge-Stone并行前缀结构
    
    // 第一级前缀计算
    wire [WIDTH:0] p_level1[WIDTH:0];
    wire [WIDTH:0] g_level1[WIDTH:0];
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level1
            if (i == 0) begin
                assign p_level1[i] = propagate[i];
                assign g_level1[i] = generate_bit[i];
            end else begin
                assign p_level1[i] = propagate[i] & propagate[i-1];
                assign g_level1[i] = generate_bit[i] | (propagate[i] & generate_bit[i-1]);
            end
        end
    endgenerate
    
    // 第二级前缀计算
    wire [WIDTH:0] p_level2[WIDTH:0];
    wire [WIDTH:0] g_level2[WIDTH:0];
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level2
            if (i < 2) begin
                assign p_level2[i] = p_level1[i];
                assign g_level2[i] = g_level1[i];
            end else begin
                assign p_level2[i] = p_level1[i] & p_level1[i-2];
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            end
        end
    endgenerate
    
    // 第三级前缀计算 (针对8位)
    wire [WIDTH:0] p_level3[WIDTH:0];
    wire [WIDTH:0] g_level3[WIDTH:0];
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_level3
            if (i < 4) begin
                assign p_level3[i] = p_level2[i];
                assign g_level3[i] = g_level2[i];
            end else begin
                assign p_level3[i] = p_level2[i] & p_level2[i-4];
                assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            end
        end
    endgenerate
    
    // 计算所有位的进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            if (i == 0) begin
                assign carry[i+1] = g_level3[i] | (p_level3[i] & carry[0]);
            end else begin
                assign carry[i+1] = g_level3[i] | (p_level3[i] & carry[0]);
            end
        end
    endgenerate
    
    // 计算最终差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign difference[i] = propagate[i] ^ carry[i];
        end
    endgenerate
    
    // 计算输出进位
    assign cout = carry[WIDTH];
    
endmodule