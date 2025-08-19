module comparator_pipelined(
    input clk,
    input rst_n,
    input [3:0] a, b,
    output reg gt, eq, lt
);

    // 流水线寄存器
    reg [3:0] a_reg1, b_reg1;
    reg [3:0] a_reg2, b_reg2;
    reg [3:0] a_reg3, b_reg3;
    reg gt_next1, eq_next1, lt_next1;
    reg gt_next2, eq_next2, lt_next2;
    reg gt_next3, eq_next3, lt_next3;

    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg1 <= 4'b0;
            b_reg1 <= 4'b0;
        end else begin
            a_reg1 <= a;
            b_reg1 <= b;
        end
    end

    // 第二级流水线 - 高位比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg2 <= 4'b0;
            b_reg2 <= 4'b0;
            gt_next1 <= 1'b0;
            eq_next1 <= 1'b0;
            lt_next1 <= 1'b0;
        end else begin
            a_reg2 <= a_reg1;
            b_reg2 <= b_reg1;
            gt_next1 <= (a_reg1[3:2] > b_reg1[3:2]);
            eq_next1 <= (a_reg1[3:2] == b_reg1[3:2]);
            lt_next1 <= (a_reg1[3:2] < b_reg1[3:2]);
        end
    end

    // 第三级流水线 - 低位比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg3 <= 4'b0;
            b_reg3 <= 4'b0;
            gt_next2 <= 1'b0;
            eq_next2 <= 1'b0;
            lt_next2 <= 1'b0;
        end else begin
            a_reg3 <= a_reg2;
            b_reg3 <= b_reg2;
            gt_next2 <= (a_reg2[1:0] > b_reg2[1:0]);
            eq_next2 <= (a_reg2[1:0] == b_reg2[1:0]);
            lt_next2 <= (a_reg2[1:0] < b_reg2[1:0]);
        end
    end

    // 第四级流水线 - 结果合并
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt_next3 <= 1'b0;
            eq_next3 <= 1'b0;
            lt_next3 <= 1'b0;
        end else begin
            gt_next3 <= gt_next1 || (eq_next1 && gt_next2);
            eq_next3 <= eq_next1 && eq_next2;
            lt_next3 <= lt_next1 || (eq_next1 && lt_next2);
        end
    end

    // 第五级流水线 - 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gt <= 1'b0;
            eq <= 1'b0;
            lt <= 1'b0;
        end else begin
            gt <= gt_next3;
            eq <= eq_next3;
            lt <= lt_next3;
        end
    end

endmodule