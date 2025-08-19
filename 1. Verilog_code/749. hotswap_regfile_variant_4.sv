//SystemVerilog
module hotswap_regfile #(
    parameter DW = 28,
    parameter AW = 5,
    parameter DEFAULT_VAL = 32'hDEADBEEF
)(
    input clk,
    input rst_n,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] din,
    input [AW-1:0] rd_addr,
    output [DW-1:0] dout,
    input [31:0] reg_enable
);
    // 双端口存储器实现
    reg [DW-1:0] mem [(1<<AW)-1:0];
    
    // 预计算寄存器使能状态
    wire wr_valid = reg_enable[wr_addr];
    wire rd_valid = reg_enable[rd_addr];
    
    // 写操作优化 - 使用单条件
    wire do_write = wr_en & wr_valid;
    
    // 异步读取逻辑
    assign dout = rd_valid ? mem[rd_addr] : DEFAULT_VAL;
    
    // 时序写入逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            integer i;
            // 优化复位循环，使用局部变量
            for (i = 0; i < (1<<AW); i = i + 1) begin
                mem[i] <= DEFAULT_VAL;
            end
        end
        else if (do_write) begin
            mem[wr_addr] <= din;
        end
    end
endmodule