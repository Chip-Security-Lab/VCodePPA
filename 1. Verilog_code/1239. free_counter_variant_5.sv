//SystemVerilog
module free_counter #(parameter MAX = 255) (
    input wire clk,
    output reg [7:0] count,
    output reg tc
);
    // 内部信号定义
    wire [7:0] next_count;
    wire [7:0] p; // 传播信号
    wire [7:0] g; // 生成信号
    wire [8:0] c; // 进位信号，多一位用于最高位进位

    // 生成和传播信号
    assign p = count;
    assign g = 8'b0;
    assign c[0] = 1'b1; // 初始进位为1，实现+1操作

    // 曼彻斯特进位链实现
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);

    // 计算下一个计数值
    assign next_count[0] = p[0] ^ c[0];
    assign next_count[1] = p[1] ^ c[1];
    assign next_count[2] = p[2] ^ c[2];
    assign next_count[3] = p[3] ^ c[3];
    assign next_count[4] = p[4] ^ c[4];
    assign next_count[5] = p[5] ^ c[5];
    assign next_count[6] = p[6] ^ c[6];
    assign next_count[7] = p[7] ^ c[7];

    // 寄存器更新 - 使用if-else结构替代条件运算符
    always @(posedge clk) begin
        if (count == MAX) begin
            count <= 8'd0;
        end else begin
            count <= next_count;
        end
        
        if (count == MAX - 1) begin
            tc <= 1'b1;
        end else begin
            tc <= 1'b0;
        end
    end
endmodule