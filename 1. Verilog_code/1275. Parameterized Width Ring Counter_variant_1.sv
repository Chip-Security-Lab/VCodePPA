//SystemVerilog
module param_ring_counter #(
    parameter CNT_WIDTH = 8
)(
    input wire clk_in,
    input wire rst_in,
    output wire [CNT_WIDTH-1:0] counter_out
);
    wire [CNT_WIDTH-1:0] counter_value;
    wire [CNT_WIDTH-1:0] next_counter_value;
    
    // 下一状态逻辑子模块
    next_state_logic #(
        .WIDTH(CNT_WIDTH)
    ) next_state_inst (
        .current_value(counter_value),
        .next_value(next_counter_value)
    );
    
    // 状态寄存器子模块
    state_register #(
        .WIDTH(CNT_WIDTH)
    ) state_register_inst (
        .clk(clk_in),
        .rst(rst_in),
        .next_value(next_counter_value),
        .current_value(counter_value)
    );
    
    // 输出赋值
    assign counter_out = counter_value;
    
endmodule

// 下一状态逻辑子模块 - 计算环形计数器的下一个状态
module next_state_logic #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] current_value,
    output wire [WIDTH-1:0] next_value
);
    // 环形移位操作，最高位移动到最低位
    assign next_value = {current_value[WIDTH-2:0], current_value[WIDTH-1]};
endmodule

// 状态寄存器子模块 - 存储当前计数值并处理复位
module state_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] next_value,
    output reg [WIDTH-1:0] current_value
);
    // 时序逻辑实现
    always @(posedge clk) begin
        if (rst)
            current_value <= {{(WIDTH-1){1'b0}}, 1'b1}; // 复位为1热编码初始值
        else
            current_value <= next_value;
    end
endmodule