//SystemVerilog
module multiphase_clock(
    input sys_clk,
    input rst,
    output [7:0] phase_clks
);
    // 优化的单阶段流水线
    reg [7:0] shift_reg;
    reg valid;
    
    // 预计算的下一个状态 - 移到组合逻辑
    wire [7:0] shift_reg_next = {shift_reg[6:0], shift_reg[7]};
    
    // 单阶段流水线寄存器 - 合并了原来的两个阶段
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b00000001;
            valid <= 1'b0;
        end else begin
            shift_reg <= shift_reg_next;
            valid <= 1'b1;
        end
    end
    
    // 输出赋值 - 只有当流水线有效时才输出
    assign phase_clks = valid ? shift_reg : 8'b00000001;
endmodule