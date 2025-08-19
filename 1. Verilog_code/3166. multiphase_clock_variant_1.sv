//SystemVerilog
module multiphase_clock(
    input sys_clk,
    input rst,
    output [7:0] phase_clks
);
    reg [7:0] shift_reg;
    reg [7:0] phase_clks_buf1;
    reg [7:0] phase_clks_buf2;
    
    // 主移位寄存器逻辑
    always @(posedge sys_clk or posedge rst) begin
        if (rst)
            shift_reg <= 8'b00000001;
        else
            shift_reg <= {shift_reg[6:0], shift_reg[7]};
    end
    
    // 第一级缓冲器 - 减轻shift_reg的扇出负载
    always @(posedge sys_clk or posedge rst) begin
        if (rst)
            phase_clks_buf1 <= 8'b00000001;
        else
            phase_clks_buf1 <= shift_reg;
    end
    
    // 第二级缓冲器 - 进一步隔离并保持时序一致性
    always @(posedge sys_clk or posedge rst) begin
        if (rst)
            phase_clks_buf2 <= 8'b00000001;
        else
            phase_clks_buf2 <= phase_clks_buf1;
    end
    
    // 分配输出，使用缓冲后的信号
    assign phase_clks = phase_clks_buf2;
endmodule