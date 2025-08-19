//SystemVerilog
module d_ff_enable (
    input wire clock,
    input wire enable,
    input wire data_in,
    output wire data_out
);
    // 实例化数据控制模块
    data_controller data_ctrl (
        .clock(clock),
        .enable(enable),
        .data_in(data_in),
        .data_out(data_out)
    );
endmodule

// 数据控制子模块，负责使能控制和数据传输
module data_controller (
    input wire clock,
    input wire enable,
    input wire data_in,
    output reg data_out
);
    // 在输入端捕获数据和使能信号
    reg data_in_reg;
    reg enable_reg;
    
    // 第一级寄存器 - 捕获输入并减少输入到第一级寄存器的路径延迟
    always @(posedge clock) begin
        data_in_reg <= data_in;
        enable_reg <= enable;
    end
    
    // 第二级寄存器 - 基于注册后的使能信号处理数据
    always @(posedge clock) begin
        if (enable_reg)
            data_out <= data_in_reg;
    end
endmodule