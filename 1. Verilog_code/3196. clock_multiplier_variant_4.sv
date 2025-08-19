//SystemVerilog
module clock_multiplier #(
    parameter MULT_RATIO = 4
)(
    input clk_ref,
    output reg clk_out
);
    reg [1:0] phase_counter;
    wire [1:0] next_counter;
    
    // 先行进位加法器实现2位加法
    wire g0, p0, g1, p1; // 生成和传播信号
    wire c1, c2;         // 进位信号
    
    // 计算生成和传播信号
    assign g0 = phase_counter[0] & 1'b1;  // 与1相加的第0位进位生成
    assign p0 = phase_counter[0] ^ 1'b1;  // 与1相加的第0位进位传播
    assign g1 = phase_counter[1] & 1'b0;  // 与1相加的第1位进位生成
    assign p1 = phase_counter[1] ^ 1'b0;  // 与1相加的第1位进位传播
    
    // 计算进位
    assign c1 = g0;                      // 第0位进位输出
    assign c2 = g1 | (p1 & c1);          // 第1位进位输出（溢出）
    
    // 计算和
    assign next_counter[0] = p0;         // 第0位和
    assign next_counter[1] = p1 ^ c1;    // 第1位和
    
    always @(negedge clk_ref) begin
        phase_counter <= next_counter;
        clk_out <= next_counter[1];
    end
endmodule