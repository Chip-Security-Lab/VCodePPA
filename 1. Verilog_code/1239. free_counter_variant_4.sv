//SystemVerilog
module free_counter #(parameter MAX = 255) (
    input wire clk,
    output reg [7:0] count,
    output reg tc
);
    wire [7:0] next_count;
    wire [7:0] p, g; // 生成和传播信号
    wire [7:0] c; // 进位信号
    
    // 生成和传播信号
    assign p = count;
    assign g = 8'b0;
    
    // 先行进位加法器逻辑 - 计算各位进位信号
    assign c[0] = 1'b1; // 初始进位为1
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 计算下一个计数值 - 异或操作
    assign next_count[0] = p[0] ^ c[0];
    assign next_count[1] = p[1] ^ c[1];
    assign next_count[2] = p[2] ^ c[2];
    assign next_count[3] = p[3] ^ c[3];
    assign next_count[4] = p[4] ^ c[4];
    assign next_count[5] = p[5] ^ c[5];
    assign next_count[6] = p[6] ^ c[6];
    assign next_count[7] = p[7] ^ c[7];
    
    // 计数器更新逻辑
    always @(posedge clk) begin
        count <= (count == MAX) ? 8'd0 : next_count;
    end
    
    // 终端计数(Terminal Count)逻辑
    always @(posedge clk) begin
        tc <= (count == MAX - 1);
    end
endmodule