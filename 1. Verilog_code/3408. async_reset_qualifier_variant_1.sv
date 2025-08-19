//SystemVerilog
// 顶层模块：异步复位限定器
module async_reset_qualifier (
    input  wire        clk,          // 系统时钟
    input  wire        raw_reset,    // 原始复位信号
    input  wire [3:0]  qualifiers,   // 限定器控制信号
    output wire [3:0]  qualified_resets // 限定后的复位信号
);
    // 内部信号声明
    reg         reset_sync1, reset_sync2;  // 用于复位同步的寄存器
    wire        synchronized_reset;        // 同步后的复位信号
    reg  [3:0]  qualifiers_reg;           // 寄存器化的限定器
    reg  [3:0]  pre_qualified_resets;     // 预处理的复位信号
    
    // 第一阶段：复位信号同步 - 减少亚稳态风险
    always @(posedge clk or posedge raw_reset) begin
        if (raw_reset) begin
            reset_sync1 <= 1'b1;
            reset_sync2 <= 1'b1;
        end else begin
            reset_sync1 <= 1'b0;
            reset_sync2 <= reset_sync1;
        end
    end
    
    assign synchronized_reset = reset_sync2;
    
    // 第二阶段：限定器信号寄存器化 - 切分数据路径，降低组合逻辑深度
    always @(posedge clk) begin
        qualifiers_reg <= qualifiers;
    end
    
    // 第三阶段：生成预限定复位信号 - 主要数据处理路径
    always @(posedge clk or posedge synchronized_reset) begin
        if (synchronized_reset) begin
            pre_qualified_resets <= 4'b0000;
        end else begin
            pre_qualified_resets[0] <= synchronized_reset & qualifiers_reg[0];
            pre_qualified_resets[1] <= synchronized_reset & qualifiers_reg[1];
            pre_qualified_resets[2] <= synchronized_reset & qualifiers_reg[2];
            pre_qualified_resets[3] <= synchronized_reset & qualifiers_reg[3];
        end
    end
    
    // 第四阶段：输出驱动 - 为各个目标系统提供限定复位
    assign qualified_resets = pre_qualified_resets;
    
    // 断言检查 - 确保正确操作
    // synopsys translate_off
    always @(posedge clk) begin
        if (|qualified_resets) begin
            assert(raw_reset) else $error("限定复位有效，但原始复位未激活");
        end
    end
    // synopsys translate_on
    
endmodule