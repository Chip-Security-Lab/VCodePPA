module subtractor_sync (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 低电平有效复位信号
    input wire valid_i,       // 输入数据有效信号
    output reg ready_o,       // 输出就绪信号
    input wire [7:0] a,       // 被减数
    input wire [7:0] b,       // 减数
    output reg valid_o,       // 输出数据有效信号
    input wire ready_i,       // 输入就绪信号
    output reg [7:0] res      // 差
);

reg [7:0] a_reg;             // 被减数寄存器
reg [7:0] b_reg;             // 减数寄存器
reg [7:0] res_reg;           // 结果寄存器
reg valid_reg;               // 有效信号寄存器

// 复位逻辑块 - 处理所有寄存器的复位
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_reg <= 8'd0;
        b_reg <= 8'd0;
        res_reg <= 8'd0;
        valid_reg <= 1'b0;
        ready_o <= 1'b1;
        valid_o <= 1'b0;
    end
end

// 输入数据捕获块 - 处理输入数据的寄存
always @(posedge clk) begin
    if (valid_i && ready_o) begin
        a_reg <= a;
        b_reg <= b;
        valid_reg <= 1'b1;
        ready_o <= 1'b0;
    end
end

// 减法运算块 - 执行减法操作
always @(posedge clk) begin
    if (valid_reg) begin
        res_reg <= a_reg - b_reg;
        valid_o <= 1'b1;
    end
end

// 输出控制块 - 处理输出数据的传输
always @(posedge clk) begin
    if (valid_o && ready_i) begin
        res <= res_reg;
        valid_o <= 1'b0;
        valid_reg <= 1'b0;
        ready_o <= 1'b1;
    end
end

endmodule