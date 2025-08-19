module subtractor_4bit (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 异步复位信号
    input wire [3:0] a,      // 被减数
    input wire [3:0] b,      // 减数
    output reg [3:0] res     // 差
);

// 流水线寄存器
reg [3:0] a_reg;
reg [3:0] b_reg;
reg [3:0] res_reg;

// 并行前缀减法器信号
wire [3:0] b_comp;           // b的补码
wire [3:0] g;                // 生成信号
wire [3:0] p;                // 传播信号
wire [3:0] c;                // 进位信号
wire [3:0] sum;              // 和信号

// 计算b的补码
assign b_comp = ~b_reg + 1'b1;

// 生成和传播信号
assign g = a_reg & b_comp;
assign p = a_reg ^ b_comp;

// 并行前缀进位计算
assign c[0] = g[0];
assign c[1] = g[1] | (p[1] & c[0]);
assign c[2] = g[2] | (p[2] & c[1]);
assign c[3] = g[3] | (p[3] & c[2]);

// 计算最终结果
assign sum = p ^ {1'b0, c[2:0]};

// 流水线控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_reg <= 4'b0;
        b_reg <= 4'b0;
        res_reg <= 4'b0;
        res <= 4'b0;
    end else begin
        // 输入寄存器
        a_reg <= a;
        b_reg <= b;
        
        // 结果寄存器
        res_reg <= sum;
        res <= res_reg;
    end
end

endmodule