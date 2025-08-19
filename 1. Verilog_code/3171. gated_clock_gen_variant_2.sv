//SystemVerilog
//-----------------------------------------------------------------------------
// 模块名称: gated_clock_gen
// 功能描述: 门控时钟生成器，增强型流水线结构设计
//-----------------------------------------------------------------------------
module gated_clock_gen (
    input  wire master_clk,    // 主时钟输入
    input  wire gate_enable,   // 门控使能信号
    input  wire rst,           // 异步复位信号
    output wire gated_clk,     // 门控后的时钟输出
    output wire valid_out      // 输出有效信号
);

    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线数据寄存器
    reg gate_enable_stage1, gate_enable_stage2;
    reg enable_latch_stage1, enable_latch_stage2;
    
    // 边沿检测和同步逻辑
    reg gate_enable_sync;
    
    // 时钟门控控制信号
    wire clock_gate_control;
    
    // 阶段1: 输入同步与有效信号初始化
    always @(posedge master_clk or posedge rst) begin
        if (rst) begin
            gate_enable_sync <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            gate_enable_sync <= gate_enable;
            valid_stage1 <= 1'b1;  // 一旦启动，流水线开始运行
        end
    end
    
    // 阶段2: 在时钟下降沿捕获门控信号 + 流水线寄存器
    always @(negedge master_clk or posedge rst) begin
        if (rst) begin
            enable_latch_stage1 <= 1'b0;
        end else begin
            enable_latch_stage1 <= gate_enable_sync;
        end
    end
    
    // 阶段3: 流水线寄存传递 - 正沿触发
    always @(posedge master_clk or posedge rst) begin
        if (rst) begin
            gate_enable_stage1 <= 1'b0;
            gate_enable_stage2 <= 1'b0;
            enable_latch_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // 数据流水线
            gate_enable_stage1 <= gate_enable_sync;
            gate_enable_stage2 <= gate_enable_stage1;
            enable_latch_stage2 <= enable_latch_stage1;
            
            // 控制流水线
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线控制逻辑：时钟门控前馈控制
    // 在级联流水线中插入前馈路径以减少延迟
    assign clock_gate_control = (valid_stage3) ? enable_latch_stage2 : 
                              (valid_stage2) ? enable_latch_stage1 : 
                              gate_enable_sync;
    
    // 输出阶段: 门控时钟生成
    assign gated_clk = master_clk & clock_gate_control;
    assign valid_out = valid_stage3;

    // 流水线状态调试信号 (可选择在RTL实现中移除)
    `ifdef DEBUG_MODE
    wire [2:0] pipeline_state = {valid_stage3, valid_stage2, valid_stage1};
    `endif

endmodule