module unsigned_subtractor_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [7:0]  diff
);

    // 流水线寄存器
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [7:0] b_inv_reg;
    reg [7:0] sum_reg;
    reg       carry_reg;

    // 第一阶段: 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 第二阶段: 取反操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_inv_reg <= 8'b0;
        end else begin
            b_inv_reg <= ~b_reg;
        end
    end

    // 第三阶段: 加法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {carry_reg, sum_reg} <= 9'b0;
        end else begin
            {carry_reg, sum_reg} <= a_reg + b_inv_reg + 1'b1;
        end
    end

    // 第四阶段: 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
        end else begin
            diff <= sum_reg;
        end
    end

endmodule