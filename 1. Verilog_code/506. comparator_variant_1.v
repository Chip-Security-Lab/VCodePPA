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
    reg [3:0] a_reg, b_reg;
    reg gt_reg, eq_reg, lt_reg;

    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // 比较逻辑级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt_reg <= 1'b0;
            eq_reg <= 1'b0;
            lt_reg <= 1'b0;
        end else begin
            gt_reg <= (a_reg > b_reg);
            eq_reg <= (a_reg == b_reg);
            lt_reg <= (a_reg < b_reg);
        end
    end

    // 输出寄存器级
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