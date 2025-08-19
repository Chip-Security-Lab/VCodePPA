//SystemVerilog
module rom_multiphase #(parameter PHASES=4)(
    input clk,
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] data
);
    reg [7:0] mem [0:255];
    wire [7:0] full_addr;
    
    // 使用曼彻斯特进位链加法器计算地址
    manchester_carry_chain_adder mcc_addr(
        .a({2'b00, addr}),
        .b({phase, 6'b000000}),
        .cin(1'b0),
        .sum(full_addr),
        .cout()
    );
    
    // 初始化存储器
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    assign data = mem[full_addr];
endmodule

// 曼彻斯特进位链加法器模块 (9位)
module manchester_carry_chain_adder(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [8:0] p, g;       // 传播和生成信号 (包括进位输入)
    wire [8:0] c;          // 进位信号
    wire [8:0] prop_chain; // 进位传播链
    
    // 计算初始传播和生成信号
    assign p[7:0] = a ^ b;  // 传播 = a XOR b
    assign g[7:0] = a & b;  // 生成 = a AND b
    
    // 处理进位输入
    assign p[8] = 1'b0;
    assign g[8] = cin;
    assign c[0] = cin;
    
    // 曼彻斯特进位链计算
    // 初始化传播链
    assign prop_chain[0] = g[0] | (p[0] & cin);
    
    // 第一级传播 (位 1-2)
    assign prop_chain[1] = g[1] | (p[1] & prop_chain[0]);
    assign prop_chain[2] = g[2] | (p[2] & prop_chain[1]);
    
    // 第二级传播 (位 3-4)
    assign prop_chain[3] = g[3] | (p[3] & prop_chain[2]);
    assign prop_chain[4] = g[4] | (p[4] & prop_chain[3]);
    
    // 第三级传播 (位 5-6)
    assign prop_chain[5] = g[5] | (p[5] & prop_chain[4]);
    assign prop_chain[6] = g[6] | (p[6] & prop_chain[5]);
    
    // 第四级传播 (位 7-8)
    assign prop_chain[7] = g[7] | (p[7] & prop_chain[6]);
    assign prop_chain[8] = g[8] | (p[8] & prop_chain[7]); // 这一位对应输出进位
    
    // 计算各位进位
    assign c[1] = prop_chain[0];
    assign c[2] = prop_chain[1];
    assign c[3] = prop_chain[2];
    assign c[4] = prop_chain[3];
    assign c[5] = prop_chain[4];
    assign c[6] = prop_chain[5];
    assign c[7] = prop_chain[6];
    assign c[8] = prop_chain[7];
    
    // 计算各位和
    assign sum = p[7:0] ^ c[7:0];
    assign cout = c[8];
endmodule