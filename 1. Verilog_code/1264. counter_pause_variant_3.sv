//SystemVerilog
module counter_pause #(parameter WIDTH=8) (
    input clk, rst, pause,
    output reg [WIDTH-1:0] cnt
);
    wire [WIDTH-1:0] next_cnt;
    
    kogge_stone_adder #(.WIDTH(WIDTH)) adder (
        .a(cnt),
        .b({{(WIDTH-1){1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(next_cnt),
        .cout()
    );
    
    always @(posedge clk) begin
        if (rst) cnt <= 0;
        else if (!pause) cnt <= next_cnt;
    end
endmodule

module kogge_stone_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // Stage 0: 初始化生成和传播信号
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] c;
    
    // 生成初始传播(p)和生成(g)信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 内部传播(P)和生成(G)信号的二维数组
    // [level][bit_position]
    wire [LOG2(WIDTH):0][WIDTH-1:0] P, G;
    
    // 第0级: 初始P和G
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : init_pg
            assign P[0][i] = p[i];
            assign G[0][i] = g[i];
        end
    endgenerate
    
    // Kogge-Stone并行前缀树 - 完全并行化处理
    generate
        // 对每个前缀级别
        for (i = 1; i <= LOG2(WIDTH); i = i + 1) begin : prefix_level
            // 计算间距
            localparam STRIDE = 2**(i-1);
            
            // 对每个位置
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_bit
                if (j >= STRIDE) begin
                    // 并行前缀组合
                    assign P[i][j] = P[i-1][j] & P[i-1][j-STRIDE];
                    assign G[i][j] = G[i-1][j] | (P[i-1][j] & G[i-1][j-STRIDE]);
                end else begin
                    // 小于步长的位直接传递
                    assign P[i][j] = P[i-1][j];
                    assign G[i][j] = G[i-1][j];
                end
            end
        end
    endgenerate
    
    // 进位计算
    assign c[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            if (i == 0)
                assign c[i+1] = g[i] | (p[i] & cin);
            else
                assign c[i+1] = G[LOG2(WIDTH)][i] | (P[LOG2(WIDTH)][i] & cin);
        end
    endgenerate
    
    // 计算最终和
    assign sum = p ^ c[WIDTH-1:0];
    assign cout = c[WIDTH];
    
    // 函数: 计算log2(n)，向上取整
    function integer LOG2;
        input integer n;
        integer i, val;
        begin
            val = n;
            for (i = 0; val > 0; i = i + 1)
                val = val >> 1;
            LOG2 = i - 1;
        end
    endfunction
endmodule