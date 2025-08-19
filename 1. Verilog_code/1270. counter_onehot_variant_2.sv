//SystemVerilog
// 顶层模块
module counter_onehot #(
    parameter BITS = 4
)(
    input  wire clk,
    input  wire rst,
    output wire [BITS-1:0] state
);

    // 内部信号连接
    wire [BITS-1:0] current_state;
    wire [BITS-1:0] next_state_logic_out;
    reg  [BITS-1:0] next_state_reg;
    
    // 状态转换逻辑单元 - 插入流水线寄存器
    next_state_logic #(
        .WIDTH(BITS)
    ) next_state_inst (
        .clk(clk),
        .current_state(current_state),
        .next_state(next_state_logic_out)
    );
    
    // 将寄存器前移到组合逻辑之后
    always @(posedge clk) begin
        if (rst)
            next_state_reg <= {{(BITS-1){1'b0}}, 1'b1}; // 复位到第一个状态
        else
            next_state_reg <= next_state_logic_out;
    end
    
    // 简化的状态寄存器 - 无条件赋值，减少临界路径
    state_register #(
        .WIDTH(BITS)
    ) state_reg_inst (
        .clk(clk),
        .next_state(next_state_reg),
        .current_state(current_state)
    );
    
    // 输出赋值
    assign state = current_state;

endmodule

// 状态寄存器子模块 - 简化后的版本
module state_register #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire [WIDTH-1:0] next_state,
    output reg  [WIDTH-1:0] current_state
);

    // 简化的状态寄存器逻辑 - 移除了复位逻辑，减少关键路径延迟
    always @(posedge clk) begin
        current_state <= next_state;
    end

endmodule

// 状态转换逻辑子模块 - 增加流水线寄存器优化关键路径
module next_state_logic #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire [WIDTH-1:0] current_state,
    output reg  [WIDTH-1:0] next_state
);

    // 低半部分和高半部分的中间寄存器
    reg [WIDTH/2-1:0] lower_half_pipe;
    reg [WIDTH/2:0] upper_half_pipe;
    
    // 流水线第一级 - 分割组合逻辑
    always @(posedge clk) begin
        // 存储低半部分
        lower_half_pipe <= current_state[WIDTH/2-1:0];
        // 存储高半部分(包括旋转的最高位)
        upper_half_pipe <= {current_state[WIDTH-1], current_state[WIDTH-1:WIDTH/2]};
    end
    
    // 流水线第二级 - 组合最终结果
    always @(posedge clk) begin
        next_state <= {upper_half_pipe[WIDTH/2-1:0], lower_half_pipe};
    end

endmodule