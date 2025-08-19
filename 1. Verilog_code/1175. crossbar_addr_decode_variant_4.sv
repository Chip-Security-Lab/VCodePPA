//SystemVerilog
//IEEE 1364-2005
module crossbar_addr_decode #(parameter AW=4, parameter DW=16, parameter N=8) (
    input clk,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output [N*DW-1:0] data_out
);
    reg [N-1:0] sel;
    integer i;
    
    // 曼彻斯特进位链加法器模块用于地址解码计算
    wire [AW-1:0] addr_plus_one;
    manchester_carry_chain_adder #(.WIDTH(AW)) addr_increment (
        .a(addr),
        .b({{(AW-1){1'b0}}, 1'b1}),
        .sum(addr_plus_one),
        .cout()
    );

    always @(*) begin
        sel = 0;
        if(addr < N) sel[addr] = 1'b1;
    end

    genvar g;
    generate 
        for(g=0; g<N; g=g+1) begin: gen_out
            assign data_out[(g*DW) +: DW] = sel[g] ? data_in : 0;
        end
    endgenerate
endmodule

module manchester_carry_chain_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output cout
);
    // 定义进位生成和传播信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH:0] c;   // 进位信号，包括进位输入和输出
    
    // 生成初始的传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i];  // 传播信号
            assign g[i] = a[i] & b[i];  // 生成信号
        end
    endgenerate
    
    // 初始进位为0
    assign c[0] = 1'b0;
    
    // 曼彻斯特进位链实现
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carries
            // 曼彻斯特进位链结构：c[i+1] = g[i] | (p[i] & c[i])
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // 计算和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ c[i];  // 和 = 传播信号 ^ 前一位进位
        end
    endgenerate
    
    // 最终进位输出
    assign cout = c[WIDTH];
endmodule