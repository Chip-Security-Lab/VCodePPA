module param_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output [WIDTH:0] sum
);
    // 带状进位加法器实现
    wire [WIDTH-1:0] g, p;  // 生成和传播信号
    wire [WIDTH:0] c;       // 进位信号
    wire [WIDTH-1:0] s;     // 和信号
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 带状进位计算
    assign c[0] = 0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // 计算和
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin : sum_calc
            assign s[k] = p[k] ^ c[k];
        end
    endgenerate
    
    // 输出结果
    assign sum = {c[WIDTH], s};
endmodule