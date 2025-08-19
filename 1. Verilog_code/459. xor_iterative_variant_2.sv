//SystemVerilog
module xor_iterative(
    input [3:0] x,
    input [3:0] y,
    output reg [3:0] z
);
    wire [4:0] sum;
    
    skip_carry_adder sca_inst(
        .a({1'b0, x}),  // 扩展为5位
        .b({1'b0, y}),  // 扩展为5位
        .sum(sum)
    );
    
    always @(*) begin
        z = sum[3:0];
    end
endmodule

module skip_carry_adder(
    input [4:0] a,
    input [4:0] b,
    output [4:0] sum
);
    // 声明内部信号
    wire [4:0] p;           // 传播信号
    wire [4:0] g;           // 生成信号
    wire [4:0] c;           // 进位信号
    wire [1:0] block_p;     // 分块传播信号
    wire [1:0] block_g;     // 分块生成信号
    wire block_cin;         // 分块进位输入
    
    // 生成逐位传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 初始进位为0
    assign c[0] = 1'b0;
    
    // 第一个分块（低3位）
    assign block_p[0] = &p[2:0];  // 块内所有位都传播
    assign block_g[0] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]); // 块生成
    
    // 第二个分块（高2位）
    assign block_p[1] = &p[4:3];  // 块内所有位都传播
    assign block_g[1] = g[4] | (p[4] & g[3]); // 块生成
    
    // 计算第二个分块的进位输入
    assign block_cin = block_g[0] | (block_p[0] & c[0]);
    
    // 计算进位
    // 低3位内部进位计算
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = block_cin;
    
    // 高2位内部进位计算
    assign c[4] = block_g[1] | (block_p[1] & block_cin);
    
    // 计算最终和
    assign sum = p ^ {c[4:1], 1'b0};
endmodule