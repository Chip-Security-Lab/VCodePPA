//SystemVerilog
//IEEE 1364-2005 Verilog
module error_detect_decoder (
    input wire clk,          // 添加时钟信号用于流水线
    input wire rst_n,        // 添加复位信号用于初始化
    input wire [1:0] addr,   // 地址输入
    input wire valid,        // 有效信号
    output reg [3:0] select, // 修改为寄存器输出，优化时序
    output reg error         // 修改为寄存器输出，优化时序
);
    // 内部流水线寄存器
    reg [1:0] addr_stage1;
    reg valid_stage1;
    reg [3:0] select_comb;
    reg error_comb;
    
    // 第一级流水线 - 捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid;
        end
    end
    
    // 组合逻辑 - 计算选择信号和错误标志
    always @(*) begin
        // 选择信号生成
        select_comb = 4'b0000;
        if (valid_stage1)
            select_comb = (4'b0001 << addr_stage1);
        else
            select_comb = 4'b0000;
            
        // 错误检测逻辑
        error_comb = ~valid_stage1;
    end
    
    // 第二级流水线 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 4'b0000;
            error <= 1'b1;   // 默认错误状态
        end else begin
            select <= select_comb;
            error <= error_comb;
        end
    end

endmodule