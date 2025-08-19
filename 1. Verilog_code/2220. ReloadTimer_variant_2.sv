//SystemVerilog IEEE 1364-2005
module ReloadTimer #(
    parameter DW = 8  // 计数器位宽参数
) (
    input wire clk,           // 系统时钟
    input wire rst_n,         // 低电平有效复位
    input wire [DW-1:0] reload_val,  // 重载值
    output reg timeout        // 超时信号
);

    // 数据通路寄存器
    reg [DW-1:0] counter_reg;     // 当前计数值
    reg [DW-1:0] reload_val_reg;  // 寄存reload_val以切断关键路径
    
    // 控制信号
    wire reload_condition;         // 重载条件
    wire counter_at_one;           // 计数器为1的标志
    
    // 控制逻辑 - 检测重载条件
    assign reload_condition = !rst_n || timeout;
    
    // 数据路径逻辑 - 计数器为1的检测
    assign counter_at_one = (counter_reg == 1'b1);
    
    // 合并所有posedge clk触发的always块
    always @(posedge clk) begin
        // 寄存输入信号，切分关键路径
        reload_val_reg <= reload_val;
        
        // 计数器逻辑 - 主数据通路
        if (reload_condition) begin
            counter_reg <= reload_val_reg;  // 重载计数器
        end else begin
            counter_reg <= counter_reg - 1'b1;  // 计数器递减
        end
        
        // 超时输出逻辑 - 基于计数器值产生timeout信号
        timeout <= counter_at_one;  // 下一周期产生超时信号
    end

endmodule