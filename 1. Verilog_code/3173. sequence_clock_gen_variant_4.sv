//SystemVerilog
module sequence_clock_gen(
    input clk,
    input rst,
    input [7:0] pattern,
    output reg seq_out
);
    reg [2:0] bit_pos;
    wire [2:0] next_bit_pos;
    
    // 先行进位加法器实现(3位加法)
    wire [2:0] p, g;
    wire [2:0] c;
    
    // 生成传播信号和生成信号
    assign p[0] = bit_pos[0];
    assign p[1] = bit_pos[1];
    assign p[2] = bit_pos[2];
    
    assign g[0] = 1'b0;        // 生成信号(与1相加时为0)
    assign g[1] = bit_pos[0];  // 进位生成
    assign g[2] = bit_pos[1] & bit_pos[0];
    
    // 先行进位逻辑
    assign c[0] = 1'b1;        // 加数为1，所以初始进位为1
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    
    // 计算和
    assign next_bit_pos[0] = p[0] ^ c[0];
    assign next_bit_pos[1] = p[1] ^ c[1];
    assign next_bit_pos[2] = p[2] ^ c[2];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos <= 3'd0;
            seq_out <= 1'b0;
        end else begin
            seq_out <= pattern[bit_pos];
            bit_pos <= next_bit_pos;
        end
    end
endmodule