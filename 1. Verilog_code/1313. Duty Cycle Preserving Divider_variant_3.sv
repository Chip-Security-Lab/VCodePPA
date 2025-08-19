//SystemVerilog
`timescale 1ns / 1ps

module duty_preserve_divider (
    input wire clock_in, 
    input wire n_reset, 
    input wire [3:0] div_ratio,
    output reg clock_out
);
    reg [3:0] counter;
    
    // 带状进位加法器的中间信号
    wire [3:0] p, g;  // 传播和生成信号
    wire [4:0] c;     // 进位信号，多一位用于进位输出
    wire [3:0] next_counter;
    
    // 前向寄存器重定时：将组合逻辑的计算移到寄存器之前
    // 生成传播和生成信号
    assign p = counter ^ 4'b0001;  // 传播 = a XOR b
    assign g = counter & 4'b0001;  // 生成 = a AND b
    
    // 带状进位逻辑
    assign c[0] = 1'b0;  // 初始进位为0
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 计算和
    assign next_counter = p ^ {c[3:0]};
    
    // 前置判断逻辑，将组合逻辑提前计算
    wire counter_will_reset;
    assign counter_will_reset = (counter >= div_ratio - 1);
    
    // 将next_counter的选择逻辑提前，减少输入到寄存器的路径延迟
    wire [3:0] final_next_counter;
    assign final_next_counter = counter_will_reset ? 4'd0 : next_counter;
    
    // 时钟输出逻辑提前计算
    wire next_clock_out;
    assign next_clock_out = counter_will_reset ? ~clock_out : clock_out;
    
    always @(posedge clock_in or negedge n_reset) begin
        if (!n_reset) begin
            counter <= 4'd0;
            clock_out <= 1'b0;
        end else begin
            counter <= final_next_counter;
            clock_out <= next_clock_out;
        end
    end
endmodule