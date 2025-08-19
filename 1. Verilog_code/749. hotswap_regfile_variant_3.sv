//SystemVerilog
module hotswap_regfile #(
    parameter DW = 28,
    parameter AW = 5,
    parameter DEFAULT_VAL = 32'hDEADBEEF
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [AW-1:0] wr_addr,
    input wire [DW-1:0] din,
    input wire [AW-1:0] rd_addr,
    output wire [DW-1:0] dout,
    // 热插拔控制接口
    input wire [31:0] reg_enable    // 每个bit对应寄存器的使能状态
);

    // 使用参数定义存储器大小，提高可读性和可维护性
    localparam MEM_DEPTH = (1<<AW);
    
    // 显式声明寄存器类型，改善工具的类型推断
    reg [DW-1:0] mem [0:MEM_DEPTH-1];
    reg [DW-1:0] dout_reg;
    
    // 预计算使能信号，减少关键路径延迟
    wire wr_reg_enabled = reg_enable[wr_addr];
    wire rd_reg_enabled = reg_enable[rd_addr];
    wire effective_wr_en = wr_en & wr_reg_enabled;
    
    // 存储器写入逻辑优化
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            // 使用生成循环初始化，可能允许更好的综合
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                mem[i] <= DEFAULT_VAL;
            end
        end 
        else if (effective_wr_en) begin
            mem[wr_addr] <= din;
        end
    end

    // 注册读取逻辑，实现寄存器输出以改善时序
    always @(posedge clk) begin
        if (!rst_n) begin
            dout_reg <= DEFAULT_VAL;
        end
        else begin
            dout_reg <= rd_reg_enabled ? mem[rd_addr] : DEFAULT_VAL;
        end
    end
    
    // 允许使用组合逻辑输出或寄存器输出
    // 通过参数化实现，增加设计的灵活性
    assign dout = dout_reg;

endmodule