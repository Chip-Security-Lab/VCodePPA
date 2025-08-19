//SystemVerilog
module async_load_dff (
    input wire clk,          // 时钟信号
    input wire load,         // 异步加载信号
    input wire [3:0] data,   // 加载数据输入
    output reg [3:0] q       // 寄存器输出
);
    // 增加流水线深度的中间寄存器
    reg [3:0] stage1_data;   // 第一级流水线寄存器
    reg [3:0] stage2_data;   // 第二级流水线寄存器
    reg [3:0] next_q;        // 组合逻辑结果寄存器
    reg load_stage1;         // 加载信号流水线寄存器
    reg load_stage2;         // 加载信号流水线寄存器
    
    // 第一级流水线 - 捕获输入数据和控制信号
    always @(posedge clk) begin
        stage1_data <= data;
        load_stage1 <= load;
    end
    
    // 第二级流水线 - 传递数据和控制信号
    always @(posedge clk) begin
        stage2_data <= stage1_data;
        load_stage2 <= load_stage1;
    end
    
    // 确定下一个状态的组合逻辑 - 拆分计算负载
    always @(*) begin
        if (load_stage2)
            next_q = stage2_data;
        else
            next_q = q + 4'd1;
    end
    
    // 最终输出寄存器更新 - 保持异步加载功能
    always @(posedge clk or posedge load) begin
        if (load)
            q <= data;        // 异步加载直接应用
        else
            q <= next_q;      // 同步更新使用流水线结果
    end
    
endmodule