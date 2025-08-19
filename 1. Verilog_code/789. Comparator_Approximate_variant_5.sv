//SystemVerilog
module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3 // 最大允许差值
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);
    wire [WIDTH-1:0] larger, smaller;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // 确定较大和较小的输入值
    assign larger = (data_p > data_q) ? data_p : data_q;
    assign smaller = (data_p > data_q) ? data_q : data_p;
    
    // 并行前缀减法器实现
    // 1. 生成阶段 - 计算各位的生成(generate)和传播(propagate)信号
    wire [WIDTH-1:0] g, p;
    assign g = ~smaller;  // 生成信号
    assign p = ~larger;   // 传播信号
    
    // 2. 前缀计算阶段 - 计算借位信号
    assign borrow[0] = 1'b1; // 减法的初始借位为1（补码减法的特性）
    
    // 并行前缀网络计算借位
    // 第一级前缀计算
    wire [WIDTH-1:0] g_l1, p_l1;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 2) begin: prefix_level1
            // 扁平化条件结构
            if (i+1 < WIDTH) begin
                // 合并相邻的两位
                assign g_l1[i] = g[i] | (p[i] & g[i+1]);
                assign p_l1[i] = p[i] & p[i+1];
                assign g_l1[i+1] = g[i+1];
                assign p_l1[i+1] = p[i+1];
            end else begin
                // 处理奇数位宽的情况
                assign g_l1[i] = g[i];
                assign p_l1[i] = p[i];
            end
        end
    endgenerate
    
    // 第二级前缀计算
    wire [WIDTH-1:0] g_l2, p_l2;
    generate
        for (genvar i = 0; i < WIDTH; i = i + 4) begin: prefix_level2
            // 扁平化第一种情况：i+2 < WIDTH 且 i+3 < WIDTH
            if (i+2 < WIDTH && i+3 < WIDTH) begin
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i+2]);
                assign p_l2[i] = p_l1[i] & p_l1[i+2];
                assign g_l2[i+1] = g_l1[i+1] | (p_l1[i+1] & g_l1[i+3]);
                assign p_l2[i+1] = p_l1[i+1] & p_l1[i+3];
                assign g_l2[i+2] = g_l1[i+2];
                assign p_l2[i+2] = p_l1[i+2];
                assign g_l2[i+3] = g_l1[i+3];
                assign p_l2[i+3] = p_l1[i+3];
            end
            // 扁平化第二种情况：i+2 < WIDTH 但 i+3 >= WIDTH
            else if (i+2 < WIDTH) begin
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i+2]);
                assign p_l2[i] = p_l1[i] & p_l1[i+2];
                assign g_l2[i+1] = g_l1[i+1];
                assign p_l2[i+1] = p_l1[i+1];
                assign g_l2[i+2] = g_l1[i+2];
                assign p_l2[i+2] = p_l1[i+2];
            end
            // 扁平化第三种情况：i+2 >= WIDTH
            else begin
                for (genvar j = i; j < WIDTH; j = j + 1) begin
                    assign g_l2[j] = g_l1[j];
                    assign p_l2[j] = p_l1[j];
                end
            end
        end
    endgenerate
    
    // 第三级前缀计算 (适用于宽度大于4的情况)
    wire [WIDTH-1:0] g_l3, p_l3;
    generate
        if (WIDTH > 4) begin
            for (genvar i = 0; i < WIDTH; i = i + 8) begin: prefix_level3
                // 扁平化条件：i+4 < WIDTH
                if (i+4 < WIDTH) begin
                    assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i+4]);
                    assign p_l3[i] = p_l2[i] & p_l2[i+4];
                    
                    for (genvar j = 1; j < 8 && i+j < WIDTH; j = j + 1) begin
                        // 扁平化内部条件：j < 4 且 i+j+4 < WIDTH
                        if (j < 4 && i+j+4 < WIDTH) begin
                            assign g_l3[i+j] = g_l2[i+j] | (p_l2[i+j] & g_l2[i+j+4]);
                            assign p_l3[i+j] = p_l2[i+j] & p_l2[i+j+4];
                        end
                        // 扁平化：其他情况
                        else begin
                            assign g_l3[i+j] = g_l2[i+j];
                            assign p_l3[i+j] = p_l2[i+j];
                        end
                    end
                end else begin
                    // 处理边界情况
                    for (genvar j = i; j < WIDTH; j = j + 1) begin
                        assign g_l3[j] = g_l2[j];
                        assign p_l3[j] = p_l2[j];
                    end
                end
            end
        end else begin
            // 对于位宽小于等于4的情况，直接使用第二级结果
            for (genvar i = 0; i < WIDTH; i = i + 1) begin
                assign g_l3[i] = g_l2[i];
                assign p_l3[i] = p_l2[i];
            end
        end
    endgenerate
    
    // 3. 借位传播并计算差值
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: diff_calc
            assign borrow[i+1] = g_l3[i] | (p_l3[i] & borrow[i]);
            assign diff[i] = larger[i] ^ smaller[i] ^ borrow[i];
        end
    endgenerate
    
    // 比较差值是否小于等于阈值
    assign approx_eq = (diff <= THRESHOLD);
endmodule