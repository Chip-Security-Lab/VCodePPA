//SystemVerilog
module add_xor_operator (
    input wire clk,
    input wire rst_n, 
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] sum,
    output reg [7:0] xor_result
);

    // 输入寄存器
    reg [7:0] a_reg, b_reg;
    
    // 带状进位加法器中间信号
    wire [7:0] g, p;  // Generate and Propagate
    wire [7:0] c;     // Carry bits
    
    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 生成和传播信号计算
    assign g = a_reg & b_reg;  // Generate
    assign p = a_reg ^ b_reg;  // Propagate
    
    // 进位链计算
    assign c[0] = 0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    // 输出寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'b0;
            xor_result <= 8'b0;
        end else begin
            sum <= p ^ c;  // 最终和
            xor_result <= p;  // 异或结果
        end
    end

endmodule