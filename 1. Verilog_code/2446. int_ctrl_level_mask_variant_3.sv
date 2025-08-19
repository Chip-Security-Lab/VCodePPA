//SystemVerilog
module int_ctrl_level_mask #(
    parameter N = 4
)(
    input                  clk,      // 系统时钟
    input                  rst_n,    // 低电平有效复位
    input      [N-1:0]     int_in,   // 中断输入信号
    input      [N-1:0]     mask_reg, // 中断掩码寄存器
    output reg [N-1:0]     int_out   // 中断输出信号
);

    // 优化布尔表达式 - 直接在always块中计算掩码
    // 避免额外的wire声明和assign语句，减少硬件资源
    
    // 时钟触发的寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {N{1'b0}};
        end else begin
            // 直接在时序逻辑中应用掩码，减少一层组合逻辑路径
            int_out <= int_in & mask_reg;
        end
    end

endmodule