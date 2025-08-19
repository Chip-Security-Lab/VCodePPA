//SystemVerilog
module loadable_counter (
    input wire clk, rst, load, en,
    input wire [3:0] data,
    output reg [3:0] count
);
    // 内部信号
    wire [3:0] next_count;
    wire [3:0] p, g; // 生成和传播信号
    wire [3:0] c; // 进位信号

    // 跳跃进位加法器实现
    // 生成与传播信号
    assign p = count;
    assign g = 4'b0000;

    // 进位生成逻辑
    assign c[0] = 1'b1; // 加1操作的初始进位
    assign c[1] = p[0] & c[0];
    assign c[2] = p[1] & p[0] & c[0];
    assign c[3] = p[2] & p[1] & p[0] & c[0];

    // 计算和
    assign next_count[0] = p[0] ^ c[0];
    assign next_count[1] = p[1] ^ c[1];
    assign next_count[2] = p[2] ^ c[2];
    assign next_count[3] = p[3] ^ c[3];

    // 时序逻辑
    always @(posedge clk) begin
        if (rst)
            count <= 4'b0000;
        else if (load)
            count <= data;
        else if (en)
            count <= next_count;
    end
endmodule