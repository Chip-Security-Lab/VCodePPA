//SystemVerilog
// 顶层模块
module sync_reset_ring_counter (
    input  wire       clock,
    input  wire       reset, // Active-high reset
    output wire [3:0] out
);
    // 内部连线
    wire [3:0] counter_state;
    
    // 实例化状态逻辑子模块
    state_controller state_ctrl (
        .clk    (clock),
        .rst    (reset),
        .state  (counter_state)
    );
    
    // 实例化输出驱动子模块
    output_driver out_drv (
        .state  (counter_state),
        .out    (out)
    );
    
endmodule

// 状态控制器子模块
module state_controller (
    input  wire       clk,
    input  wire       rst,
    output reg  [3:0] state
);
    // 参数定义
    localparam INIT_STATE = 4'b0001;
    
    // 状态更新逻辑
    always @(posedge clk) begin
        if (rst)
            state <= INIT_STATE; // 复位到初始状态
        else
            state <= {state[2:0], state[3]}; // 循环移位操作
    end
    
endmodule

// 输出驱动子模块
module output_driver (
    input  wire [3:0] state,
    output wire [3:0] out
);
    // 直接将状态映射到输出
    assign out = state;
    
endmodule