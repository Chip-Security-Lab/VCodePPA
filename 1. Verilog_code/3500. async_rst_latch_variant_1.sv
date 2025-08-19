//SystemVerilog
// 顶层模块
module async_rst_latch #(parameter WIDTH=8)(
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] latch_out
);
    // 控制信号生成
    wire [1:0] ctrl;
    
    // 实例化控制逻辑模块
    ctrl_logic ctrl_unit (
        .rst(rst),
        .en(en),
        .ctrl(ctrl)
    );
    
    // 实例化输出值处理模块
    output_handler #(
        .WIDTH(WIDTH)
    ) output_unit (
        .ctrl(ctrl),
        .din(din),
        .latch_out(latch_out)
    );
    
endmodule

// 控制逻辑模块 - 处理rst和en信号生成控制信号
module ctrl_logic (
    input wire rst,
    input wire en,
    output reg [1:0] ctrl
);
    // 组合rst和en为控制变量
    always @(*) begin
        ctrl = {rst, en};
    end
endmodule

// 输出处理模块 - 根据控制信号生成输出值
module output_handler #(parameter WIDTH=8)(
    input wire [1:0] ctrl,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] latch_out
);
    always @(*) begin
        // 使用case语句处理不同控制状态
        case(ctrl)
            2'b10,  // rst=1, en=0
            2'b11:  // rst=1, en=1 (rst优先级高于en)
                latch_out = {WIDTH{1'b0}};
            
            2'b01:  // rst=0, en=1
                latch_out = din;
                
            2'b00:  // rst=0, en=0
                latch_out = latch_out; // 保持当前值
        endcase
    end
endmodule