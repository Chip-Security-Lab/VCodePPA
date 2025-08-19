//SystemVerilog
// 顶层模块
module pl_reg_latch #(
    parameter W = 8
) (
    input  wire       gate,
    input  wire       load,
    input  wire [W-1:0] d,
    output wire [W-1:0] q
);
    // 内部连接信号
    wire ctrl_enable;
    
    // 实例化控制逻辑子模块
    control_unit control_inst (
        .gate(gate),
        .load(load),
        .ctrl_enable(ctrl_enable)
    );
    
    // 实例化数据处理子模块
    data_latch #(
        .WIDTH(W)
    ) data_inst (
        .ctrl_enable(ctrl_enable),
        .data_in(d),
        .data_out(q)
    );
    
endmodule

// 控制逻辑子模块
module control_unit (
    input  wire gate,
    input  wire load,
    output wire ctrl_enable
);
    // 控制信号生成逻辑
    assign ctrl_enable = gate & load;
    
endmodule

// 数据处理子模块
module data_latch #(
    parameter WIDTH = 8
) (
    input  wire              ctrl_enable,
    input  wire [WIDTH-1:0]  data_in,
    output reg  [WIDTH-1:0]  data_out
);
    // 数据锁存逻辑
    always @* begin
        if (ctrl_enable) begin
            data_out = data_in;  // 数据透明传递
        end
        // 锁存模式：当ctrl_enable为0时保持当前值
    end
    
endmodule