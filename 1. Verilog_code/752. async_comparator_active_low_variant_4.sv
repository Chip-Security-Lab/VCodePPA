//SystemVerilog
module async_comparator_active_low(
    input wire clk,
    input wire rst_n,
    input wire [7:0] operand_1,
    input wire [7:0] operand_2,
    output wire equal_n,
    output wire greater_n,
    output wire lesser_n
);

    // 内部信号定义
    reg [7:0] op1_stage1, op2_stage1;
    reg equal_stage1, greater_stage1, lesser_stage1;
    reg equal_stage2_n, greater_stage2_n, lesser_stage2_n;

    // 输入寄存器流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op1_stage1 <= 8'h00;
            op2_stage1 <= 8'h00;
        end else begin
            op1_stage1 <= operand_1;
            op2_stage1 <= operand_2;
        end
    end

    // 比较逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_stage1 <= 1'b0;
            greater_stage1 <= 1'b0;
            lesser_stage1 <= 1'b0;
        end else begin
            equal_stage1 <= (op1_stage1 == op2_stage1);
            greater_stage1 <= (op1_stage1 > op2_stage1);
            lesser_stage1 <= (op1_stage1 < op2_stage1);
        end
    end

    // 输出极性转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_stage2_n <= 1'b1;
            greater_stage2_n <= 1'b1;
            lesser_stage2_n <= 1'b1;
        end else begin
            equal_stage2_n <= ~equal_stage1;
            greater_stage2_n <= ~greater_stage1;
            lesser_stage2_n <= ~lesser_stage1;
        end
    end

    // 输出分配
    assign equal_n = equal_stage2_n;
    assign greater_n = greater_stage2_n;
    assign lesser_n = lesser_stage2_n;

    // 综合指示
    // synthesis attribute KEEP_HIERARCHY of async_comparator_active_low is "TRUE"
    // synthesis attribute MAX_FANOUT of op1_stage1 is "16"
    // synthesis attribute MAX_FANOUT of op2_stage1 is "16"

endmodule