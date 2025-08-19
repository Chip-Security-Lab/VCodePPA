module comparator_top(
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    output reg gt,
    output reg eq,
    output reg lt
);

    // 流水线寄存器
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg gt_reg;
    reg eq_reg;
    reg lt_reg;

    // 数据路径控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            gt_reg <= 1'b0;
            eq_reg <= 1'b0;
            lt_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            gt_reg <= (a > b);
            eq_reg <= (a == b);
            lt_reg <= (a < b);
        end
    end

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt <= 1'b0;
            eq <= 1'b0;
            lt <= 1'b0;
        end else begin
            gt <= gt_reg;
            eq <= eq_reg;
            lt <= lt_reg;
        end
    end

endmodule