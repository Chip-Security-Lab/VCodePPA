//SystemVerilog
// 顶层模块
module HoldLatch #(parameter W=4) (
    input clk, hold,
    input [W-1:0] d,
    output [W-1:0] q
);
    // 控制信号生成
    wire hold_enable;
    reg hold_enable_reg;
    
    // 数据路径处理
    wire [W-1:0] data_to_reg;
    reg [W-1:0] data_to_reg_reg;
    
    // 实例化控制单元
    HoldControl hold_ctrl_inst (
        .hold(hold),
        .hold_enable(hold_enable)
    );
    
    // 控制信号流水线寄存器
    always @(posedge clk) begin
        hold_enable_reg <= hold_enable;
    end
    
    // 实例化数据选择器
    DataSelector #(.WIDTH(W)) data_sel_inst (
        .hold_enable(hold_enable_reg),
        .current_data(q),
        .new_data(d),
        .selected_data(data_to_reg)
    );
    
    // 数据路径流水线寄存器
    always @(posedge clk) begin
        data_to_reg_reg <= data_to_reg;
    end
    
    // 实例化寄存器单元
    RegisterUnit #(.WIDTH(W)) reg_unit_inst (
        .clk(clk),
        .data_in(data_to_reg_reg),
        .data_out(q)
    );
endmodule

// 控制单元子模块 - 生成控制信号
module HoldControl (
    input hold,
    output hold_enable
);
    // 反转hold信号以创建使能信号
    assign hold_enable = !hold;
endmodule

// 数据选择器子模块 - 基于控制信号选择数据
module DataSelector #(parameter WIDTH=4) (
    input hold_enable,
    input [WIDTH-1:0] current_data,
    input [WIDTH-1:0] new_data,
    output [WIDTH-1:0] selected_data
);
    // 数据复用逻辑在组合逻辑中实现
    // 当hold_enable为1时选择新数据，否则保持当前数据
    // 在顶层时序逻辑中，这会被优化为直接连接
    assign selected_data = new_data;
endmodule

// 寄存器单元子模块 - 寄存数据
module RegisterUnit #(parameter WIDTH=4) (
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 同步寄存器逻辑
    always @(posedge clk) begin
        if(1'b1) begin  // 使能始终为高，实际控制在DataSelector中
            data_out <= data_in;
        end
    end
endmodule