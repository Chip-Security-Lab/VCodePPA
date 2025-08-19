//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块：四相时钟发生器
//-----------------------------------------------------------------------------
module quad_phase_gen #(
    parameter PHASE_NUM = 4
)(
    input  wire clk,
    input  wire rst_n,
    output wire [PHASE_NUM-1:0] phase_clks
);
    // 内部连线
    wire [PHASE_NUM-1:0] next_phase;
    wire [PHASE_NUM-1:0] current_phase;
    
    // 实例化相位计算子模块
    phase_calculator #(
        .PHASE_NUM(PHASE_NUM)
    ) phase_calc_inst (
        .current_phase(current_phase),
        .next_phase(next_phase)
    );
    
    // 实例化相位寄存器子模块
    phase_register #(
        .PHASE_NUM(PHASE_NUM)
    ) phase_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .next_phase(next_phase),
        .current_phase(current_phase)
    );
    
    // 将内部相位状态连接到输出
    assign phase_clks = current_phase;
    
endmodule

//-----------------------------------------------------------------------------
// 子模块：相位寄存器 - 存储当前相位状态
//-----------------------------------------------------------------------------
module phase_register #(
    parameter PHASE_NUM = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [PHASE_NUM-1:0] next_phase,
    output reg  [PHASE_NUM-1:0] current_phase
);
    // 时序逻辑，带有异步复位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态：初始化为第一个相位
            current_phase <= {{(PHASE_NUM-1){1'b0}}, 1'b1};
        end else begin
            // 正常操作：更新为下一个相位状态
            current_phase <= next_phase;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块：相位计算器 - 计算下一个相位状态
//-----------------------------------------------------------------------------
module phase_calculator #(
    parameter PHASE_NUM = 4
)(
    input  wire [PHASE_NUM-1:0] current_phase,
    output wire [PHASE_NUM-1:0] next_phase
);
    // 组合逻辑，计算下一个相位
    // 将当前相位的最高位移到最低位，其他位上移
    assign next_phase = {current_phase[PHASE_NUM-2:0], current_phase[PHASE_NUM-1]};
endmodule