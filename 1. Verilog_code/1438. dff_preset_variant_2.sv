//SystemVerilog
// 顶层模块
module dff_preset (
    input  wire clk,    // 时钟信号
    input  wire preset, // 预置信号
    input  wire d,      // 数据输入
    output wire q       // 数据输出
);
    // 控制信号
    wire mux_sel;
    wire mux_out;
    
    // 实例化控制逻辑子模块
    control_logic ctrl_inst (
        .preset  (preset),
        .mux_sel (mux_sel)
    );
    
    // 实例化数据选择子模块
    data_mux data_mux_inst (
        .d       (d),
        .mux_sel (mux_sel),
        .mux_out (mux_out)
    );
    
    // 实例化触发器子模块
    flip_flop ff_inst (
        .clk     (clk),
        .data_in (mux_out),
        .q       (q)
    );
    
endmodule

// 控制逻辑子模块 - 处理预置信号
module control_logic (
    input  wire preset,  // 预置信号输入
    output wire mux_sel  // 多路选择器控制信号
);
    // 当preset有效时，选择器输出1
    assign mux_sel = preset;
    
endmodule

// 数据选择子模块 - 根据控制信号选择数据
module data_mux (
    input  wire d,       // 数据输入
    input  wire mux_sel, // 多路选择器控制信号
    output wire mux_out  // 多路选择器输出
);
    // 根据控制信号选择输出1或输入数据d
    assign mux_out = mux_sel ? 1'b1 : d;
    
endmodule

// 触发器子模块 - 在时钟上升沿捕获数据
module flip_flop (
    input  wire clk,     // 时钟信号
    input  wire data_in, // 数据输入
    output reg  q        // 触发器输出
);
    // 在时钟上升沿时捕获输入数据
    always @(posedge clk) begin
        q <= data_in;
    end
    
endmodule