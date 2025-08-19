//SystemVerilog
module pulse_clkgen #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg pulse
);
    reg [WIDTH-1:0] delay_cnt;
    wire [WIDTH-1:0] next_cnt;
    reg next_pulse;
    
    // 跳跃进位加法器实现
    cla_adder #(
        .WIDTH(WIDTH)
    ) counter_adder (
        .a(delay_cnt),
        .b({{(WIDTH-1){1'b0}}, 1'b1}),
        .cin(1'b0),
        .sum(next_cnt),
        .cout()
    );
    
    // 计算下一个脉冲状态
    always @(*) begin
        next_pulse = (next_cnt == {WIDTH{1'b1}}) ? 1'b1 : 1'b0;
    end
    
    always @(posedge clk) begin
        if (rst) begin
            delay_cnt <= {WIDTH{1'b0}};
            pulse <= 1'b0;
        end else begin
            delay_cnt <= next_cnt;
            pulse <= next_pulse;
        end
    end
endmodule

// 8位跳跃进位加法器
module cla_adder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] g, p;  // 生成和传播信号
    
    // 设置初始进位
    assign carry[0] = cin;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];             // 生成信号
            assign p[i] = a[i] | b[i];             // 传播信号
        end
    endgenerate
    
    // 计算每一位的进位信号 - 使用跳跃进位逻辑
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    // 计算和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate
    
    // 输出最高位进位
    assign cout = carry[WIDTH];
endmodule