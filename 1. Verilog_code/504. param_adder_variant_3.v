module param_adder #(parameter WIDTH=4) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH:0] sum
);

    // 输入寄存器级
    reg [WIDTH-1:0] a_reg;
    reg [WIDTH-1:0] b_reg;

    // 中间结果寄存器
    reg [WIDTH:0] sum_reg;

    // 输入寄存器 - 分离为两个独立的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            a_reg <= {WIDTH{1'b0}};
        else
            a_reg <= a;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            b_reg <= {WIDTH{1'b0}};
        else
            b_reg <= b;
    end

    // 加法计算级 - 优化为组合逻辑
    always @(*) begin
        sum_reg = a_reg + b_reg;
    end

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sum <= {(WIDTH+1){1'b0}};
        else
            sum <= sum_reg;
    end

endmodule