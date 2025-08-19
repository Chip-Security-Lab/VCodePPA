//SystemVerilog
// 顶层模块 - 连接控制逻辑和计数器核心
module loadable_counter (
    input wire clk,
    input wire rst,
    input wire load,
    input wire en,
    input wire [3:0] data,
    output wire [3:0] count
);
    // 内部信号
    wire [3:0] next_count;
    wire [3:0] current_count;
    
    // 计数器核心逻辑子模块
    counter_logic u_counter_logic (
        .rst(rst),
        .load(load),
        .en(en),
        .data(data),
        .current_count(current_count),
        .next_count(next_count)
    );
    
    // 寄存器子模块
    counter_register u_counter_register (
        .clk(clk),
        .rst(rst),
        .next_count(next_count),
        .current_count(current_count)
    );
    
    // 连接输出
    assign count = current_count;
    
endmodule

// 计数器逻辑子模块 - 负责计算下一个计数值
module counter_logic (
    input wire rst,
    input wire load,
    input wire en,
    input wire [3:0] data,
    input wire [3:0] current_count,
    output wire [3:0] next_count
);
    // 中间信号
    wire [3:0] incr_result;
    
    // 使用带状进位加法器实现加法
    carry_lookahead_adder cla_adder (
        .a(current_count),
        .b(4'b0001),
        .sum(incr_result)
    );
    
    // 组合逻辑确定下一个计数值
    assign next_count = rst ? 4'b0000 :
                        load ? data :
                        en ? incr_result :
                        current_count;
endmodule

// 寄存器子模块 - 存储当前计数值
module counter_register (
    input wire clk,
    input wire rst,
    input wire [3:0] next_count,
    output reg [3:0] current_count
);
    // 时序逻辑更新计数器值
    always @(posedge clk) begin
        if (rst)
            current_count <= 4'b0000;
        else
            current_count <= next_count;
    end
endmodule

// 4位带状进位加法器
module carry_lookahead_adder (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum
);
    // 内部信号
    wire [3:0] p; // 传播信号
    wire [3:0] g; // 生成信号
    wire [4:0] c; // 进位信号，多一位用于存储最后的进位输出
    
    // 生成传播(P)和生成(G)信号
    assign p = a ^ b; // 传播 = a XOR b
    assign g = a & b; // 生成 = a AND b
    
    // 初始进位
    assign c[0] = 1'b0;
    
    // 计算每一位的进位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 计算最终求和
    assign sum = p ^ c[3:0];
endmodule