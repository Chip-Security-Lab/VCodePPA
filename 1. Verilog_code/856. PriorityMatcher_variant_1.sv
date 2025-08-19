//SystemVerilog
module PriorityMatcher #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output reg [$clog2(DEPTH)-1:0] match_index,
    output reg valid
);
    wire [WIDTH-1:0] compare_results [DEPTH-1:0];
    wire [DEPTH-1:0] match_results;
    
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin: compare_loop
            CarryLookaheadComparator #(.WIDTH(WIDTH)) comp_unit (
                .a(data),
                .b(patterns[j*WIDTH +: WIDTH]),
                .equal(match_results[j])
            );
        end
    endgenerate
    
    integer i;
    always @* begin
        valid = 0;
        match_index = 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (match_results[i]) begin
                valid = 1;
                match_index = i[$clog2(DEPTH)-1:0];
            end
        end
    end
endmodule

module CarryLookaheadComparator #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output equal
);
    wire [WIDTH-1:0] xnor_result;
    
    // 生成初始比较结果
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: xnor_stage
            assign xnor_result[i] = ~(a[i] ^ b[i]);
        end
    endgenerate
    
    // 4位分组的先行进位逻辑
    wire [1:0] group_p, group_g;
    wire [3:0] p, g;
    wire [4:0] c;
    
    // 第一组P,G信号 (低4位)
    assign p[0] = xnor_result[0];
    assign p[1] = xnor_result[1];
    assign p[2] = xnor_result[2];
    assign p[3] = xnor_result[3];
    
    // 第一组G信号，比较器固定为1
    assign g[0] = 1'b1;
    assign g[1] = 1'b1;
    assign g[2] = 1'b1;
    assign g[3] = 1'b1;
    
    // 第一组内部进位计算
    assign c[0] = 1'b1; // 初始进位设为1
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 第一组的组P,G信号
    assign group_p[0] = p[3] & p[2] & p[1] & p[0];
    assign group_g[0] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    // 第二组P,G信号 (高4位)
    wire [3:0] p_high, g_high;
    wire [4:0] c_high;
    
    assign p_high[0] = xnor_result[4];
    assign p_high[1] = xnor_result[5];
    assign p_high[2] = xnor_result[6];
    assign p_high[3] = xnor_result[7];
    
    // 第二组G信号，比较器固定为1
    assign g_high[0] = 1'b1;
    assign g_high[1] = 1'b1;
    assign g_high[2] = 1'b1;
    assign g_high[3] = 1'b1;
    
    // 第二组内部进位计算，使用第一组的进位输出作为初始值
    assign c_high[0] = c[4]; // 使用第一组的进位输出
    assign c_high[1] = g_high[0] | (p_high[0] & c_high[0]);
    assign c_high[2] = g_high[1] | (p_high[1] & g_high[0]) | (p_high[1] & p_high[0] & c_high[0]);
    assign c_high[3] = g_high[2] | (p_high[2] & g_high[1]) | (p_high[2] & p_high[1] & g_high[0]) | (p_high[2] & p_high[1] & p_high[0] & c_high[0]);
    assign c_high[4] = g_high[3] | (p_high[3] & g_high[2]) | (p_high[3] & p_high[2] & g_high[1]) | (p_high[3] & p_high[2] & p_high[1] & g_high[0]) | (p_high[3] & p_high[2] & p_high[1] & p_high[0] & c_high[0]);
    
    // 第二组的组P,G信号
    assign group_p[1] = p_high[3] & p_high[2] & p_high[1] & p_high[0];
    assign group_g[1] = g_high[3] | (p_high[3] & g_high[2]) | (p_high[3] & p_high[2] & g_high[1]) | (p_high[3] & p_high[2] & p_high[1] & g_high[0]);
    
    // 最终结果 - 所有位都相等时equal为1
    assign equal = c_high[4];
endmodule