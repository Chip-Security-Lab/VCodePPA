//SystemVerilog
// 顶层模块 - 单热码计数器
module counter_onehot #(
    parameter BITS = 4
)(
    input  wire clk,       // 时钟信号
    input  wire rst,       // 复位信号
    output wire [BITS-1:0] state  // 计数器状态输出
);
    // 内部连线和寄存器
    wire [BITS-1:0] next_state;
    wire [BITS-1:0] current_state;
    
    // 实例化状态更新逻辑
    state_update #(
        .WIDTH(BITS)
    ) state_update_inst (
        .current_state(current_state),
        .next_state(next_state)
    );
    
    // 实例化状态寄存器
    state_register #(
        .WIDTH(BITS)
    ) state_register_inst (
        .clk(clk),
        .rst(rst),
        .next_state(next_state),
        .current_state(current_state)
    );
    
    // 连接到输出
    assign state = current_state;
    
endmodule

// 状态更新计算子模块
module state_update #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] current_state,
    output wire [WIDTH-1:0] next_state
);
    // 实现循环移位逻辑
    assign next_state = {current_state[WIDTH-2:0], current_state[WIDTH-1]};
    
endmodule

// 状态寄存器子模块 - 优化后的实现
module state_register #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] next_state,
    output wire [WIDTH-1:0] current_state
);
    // 分解为多个独立移位寄存器以实现后向重定时
    reg [WIDTH-1:0] state_reg;
    
    // 将每个位的寄存器单独控制，从而实现后向寄存器重定时
    genvar i;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin : shift_reg
            always @(posedge clk) begin
                if (rst)
                    state_reg[i] <= (i == 0) ? 1'b1 : 1'b0;
                else
                    state_reg[i] <= next_state[i];
            end
        end
        
        // 最后一位单独处理，完成循环移位
        always @(posedge clk) begin
            if (rst)
                state_reg[WIDTH-1] <= 1'b0;
            else
                state_reg[WIDTH-1] <= next_state[WIDTH-1];
        end
    endgenerate
    
    // 连接到输出
    assign current_state = state_reg;
    
endmodule