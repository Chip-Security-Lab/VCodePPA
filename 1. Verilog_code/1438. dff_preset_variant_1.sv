//SystemVerilog
// 顶层模块
module dff_preset_top (
    input  wire clk,
    input  wire preset,
    input  wire d,
    output wire q
);
    // 内部连线
    wire data_in;
    
    // 数据选择子模块实例化
    input_mux input_selector (
        .preset   (preset),
        .d        (d),
        .mux_out  (data_in)
    );
    
    // 寄存器子模块实例化
    register_stage register_unit (
        .clk      (clk),
        .data_in  (data_in),
        .q        (q)
    );
    
endmodule

// 输入多路复用器子模块
module input_mux (
    input  wire preset,
    input  wire d,
    output wire mux_out
);
    // 当preset激活时选择1，否则选择d
    assign mux_out = preset ? 1'b1 : d;
    
endmodule

// 寄存器单元子模块
module register_stage (
    input  wire clk,
    input  wire data_in,
    output reg  q
);
    // 时序逻辑：在时钟上升沿将输入锁存到输出
    always @(posedge clk) begin
        q <= data_in;
    end
    
endmodule