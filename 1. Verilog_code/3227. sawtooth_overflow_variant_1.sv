//SystemVerilog
module sawtooth_overflow(
    input clk,
    input rst,
    input [7:0] increment,
    output reg [7:0] sawtooth,
    output reg overflow
);
    // 跳跃进位加法器内部信号
    wire [7:0] sum;
    wire carry_out;
    
    // 实例化跳跃进位加法器
    skip_carry_adder adder(
        .a(sawtooth),
        .b(increment),
        .sum(sum),
        .cout(carry_out)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            sawtooth <= 8'd0;
            overflow <= 1'b0;
        end else begin
            sawtooth <= sum;
            overflow <= carry_out;
        end
    end
endmodule

module skip_carry_adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);
    // 内部连线
    wire [8:0] c;
    wire [1:0] block_p;
    
    // 初始进位
    assign c[0] = 1'b0;
    
    // 第一个4位块
    wire [3:0] p;
    wire [3:0] g;
    
    // 生成传播和生成信号
    assign p[0] = a[0] ^ b[0];
    assign p[1] = a[1] ^ b[1];
    assign p[2] = a[2] ^ b[2];
    assign p[3] = a[3] ^ b[3];
    
    assign g[0] = a[0] & b[0];
    assign g[1] = a[1] & b[1];
    assign g[2] = a[2] & b[2];
    assign g[3] = a[3] & b[3];
    
    // 计算第一个块的进位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    
    // 计算第一个块的传播信号
    assign block_p[0] = p[0] & p[1] & p[2] & p[3];
    
    // 第二个4位块
    wire [3:0] p_high;
    wire [3:0] g_high;
    
    // 生成高位传播和生成信号
    assign p_high[0] = a[4] ^ b[4];
    assign p_high[1] = a[5] ^ b[5];
    assign p_high[2] = a[6] ^ b[6];
    assign p_high[3] = a[7] ^ b[7];
    
    assign g_high[0] = a[4] & b[4];
    assign g_high[1] = a[5] & b[5];
    assign g_high[2] = a[6] & b[6];
    assign g_high[3] = a[7] & b[7];
    
    // 跳跃进位逻辑：如果整个第一个块都是传播的，直接使用初始进位
    wire skip_carry;
    assign skip_carry = block_p[0] ? c[0] : c[4];
    
    // 计算高位块的进位
    assign c[5] = g_high[0] | (p_high[0] & skip_carry);
    assign c[6] = g_high[1] | (p_high[1] & c[5]);
    assign c[7] = g_high[2] | (p_high[2] & c[6]);
    assign c[8] = g_high[3] | (p_high[3] & c[7]);
    
    // 计算第二个块的传播信号
    assign block_p[1] = p_high[0] & p_high[1] & p_high[2] & p_high[3];
    
    // 计算最终和
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p_high[0] ^ skip_carry;
    assign sum[5] = p_high[1] ^ c[5];
    assign sum[6] = p_high[2] ^ c[6];
    assign sum[7] = p_high[3] ^ c[7];
    
    // 最终进位输出
    assign cout = c[8];
endmodule