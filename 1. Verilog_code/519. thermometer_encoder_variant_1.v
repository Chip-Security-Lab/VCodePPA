module thermometer_encoder_top(
    input [2:0] bin,
    output [7:0] th_code
);
    
    // 实例化移位计算子模块
    shift_calculator u_shift_calc(
        .bin(bin),
        .shifted_value(shifted_value)
    );
    
    // 实例化并行前缀减法器子模块
    parallel_prefix_subtractor u_subtractor(
        .shifted_value(shifted_value),
        .th_code(th_code)
    );

endmodule

module shift_calculator(
    input [2:0] bin,
    output reg [7:0] shifted_value
);
    always @(*) begin
        shifted_value = 1 << bin;
    end
endmodule

module parallel_prefix_subtractor(
    input [7:0] shifted_value,
    output [7:0] th_code
);
    // 并行前缀减法器实现
    wire [7:0] inverted_value;
    wire [7:0] carry_out;
    wire [7:0] result;
    
    // 取反操作
    assign inverted_value = ~shifted_value;
    
    // 并行前缀加法器实现减法 (A-B = A + (~B) + 1)
    // 第一级：生成和传播信号
    wire [7:0] g, p;
    assign g = inverted_value;
    assign p = 8'hFF; // 全1表示传播
    
    // 第二级：并行前缀计算
    wire [7:0] g_level1, p_level1;
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : prefix_level1
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // 第三级：并行前缀计算
    wire [7:0] g_level2, p_level2;
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : prefix_level2
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            assign p_level2[i] = p_level1[i] & p_level1[i-2];
        end
    endgenerate
    
    // 第四级：并行前缀计算
    wire [7:0] g_level3, p_level3;
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : prefix_level3
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            assign p_level3[i] = p_level2[i] & p_level2[i-4];
        end
    endgenerate
    
    // 计算进位
    assign carry_out[0] = 1'b1; // 初始进位为1 (减法需要+1)
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_calc
            assign carry_out[i] = g_level3[i-1] | (p_level3[i-1] & carry_out[i-1]);
        end
    endgenerate
    
    // 计算最终结果
    assign result[0] = inverted_value[0] ^ carry_out[0];
    generate
        for (i = 1; i < 8; i = i + 1) begin : result_calc
            assign result[i] = inverted_value[i] ^ carry_out[i];
        end
    endgenerate
    
    // 输出结果
    assign th_code = result;
    
endmodule