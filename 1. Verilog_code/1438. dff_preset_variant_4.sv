//SystemVerilog
// 顶层模块
module dff_preset #(
    parameter PRESET_VALUE = 1'b1
)(
    input  logic clk,
    input  logic preset,
    input  logic d,
    output logic q
);
    // 内部连线
    logic preset_data;
    
    // 预置控制模块实例
    preset_controller #(
        .PRESET_VALUE(PRESET_VALUE)
    ) u_preset_ctrl (
        .preset(preset),
        .d(d),
        .preset_data(preset_data)
    );
    
    // 寄存器模块实例
    clocked_register u_register (
        .clk(clk),
        .data_in(preset_data),
        .data_out(q)
    );
    
endmodule

// 预置控制模块 - 处理数据选择和预置功能
module preset_controller #(
    parameter PRESET_VALUE = 1'b1
)(
    input  logic preset,
    input  logic d,
    output logic preset_data
);
    // 使用参数化的预置值提高灵活性
    always_comb begin
        preset_data = preset ? PRESET_VALUE : d;
    end
    
endmodule

// 寄存器模块 - 处理时序存储
module clocked_register (
    input  logic clk,
    input  logic data_in,
    output logic data_out
);
    // 使用更高效的单周期存储逻辑
    always_ff @(posedge clk) begin
        data_out <= data_in;
    end
    
endmodule