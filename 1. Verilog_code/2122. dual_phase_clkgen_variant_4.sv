//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module dual_phase_clkgen (
    input  wire sys_clk,
    input  wire async_rst,
    output wire clk_0deg,
    output wire clk_180deg
);
    // 实例化相位生成子模块
    phase_generator gen_0deg (
        .sys_clk    (sys_clk),
        .async_rst  (async_rst),
        .other_clk  (clk_180deg),
        .phase_clk  (clk_0deg),
        .init_value (1'b0)
    );
    
    phase_generator gen_180deg (
        .sys_clk    (sys_clk),
        .async_rst  (async_rst),
        .other_clk  (clk_0deg),
        .phase_clk  (clk_180deg),
        .init_value (1'b1)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// 相位时钟生成子模块 - 负责生成特定相位的时钟信号
///////////////////////////////////////////////////////////////////////////////
module phase_generator (
    input  wire sys_clk,
    input  wire async_rst,
    input  wire other_clk,
    input  wire init_value,
    output reg  phase_clk
);
    // 相位时钟生成逻辑
    always @(posedge sys_clk or posedge async_rst) begin
        if (async_rst) begin
            phase_clk <= init_value;
        end else begin
            phase_clk <= other_clk;
        end
    end
endmodule