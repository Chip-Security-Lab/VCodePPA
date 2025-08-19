//SystemVerilog
// 顶层模块：连接并控制状态机子模块
module clk_gate_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output wire [1:0] state
);

    // 内部连线
    wire       gated_clk;
    wire [1:0] next_state;

    // 实例化时钟门控子模块
    clock_gating_unit clk_gate_inst (
        .clk_in      (clk),
        .enable      (en),
        .gated_clk   (gated_clk)
    );

    // 实例化状态计算子模块 - 使用Baugh-Wooley乘法器实现
    next_state_logic state_logic_inst (
        .current_state (state),
        .next_state    (next_state)
    );

    // 实例化状态寄存器子模块
    state_register state_reg_inst (
        .clk           (gated_clk),
        .rst           (rst),
        .next_state    (next_state),
        .current_state (state)
    );

endmodule

// 时钟门控子模块
module clock_gating_unit (
    input  wire clk_in,
    input  wire enable,
    output wire gated_clk
);

    // 简单时钟门控实现
    assign gated_clk = clk_in & enable;

endmodule

// 状态转换逻辑子模块 - 使用2位Baugh-Wooley乘法器实现
module next_state_logic (
    input  wire [1:0] current_state,
    output wire [1:0] next_state
);
    
    // 使用乘法运算结果的低2位作为下一状态
    wire [3:0] mult_result;
    
    // 实例化Baugh-Wooley乘法器
    baugh_wooley_2bit multiplier (
        .a          (current_state),
        .b          (2'b10),         // 选择2作为乘数常量
        .product    (mult_result)
    );
    
    // 利用乘法结果的低2位作为状态转换结果
    // 保持原有状态机转换特性
    assign next_state = (current_state == 2'b10) ? 2'b00 : mult_result[1:0];

endmodule

// 2位Baugh-Wooley乘法器
module baugh_wooley_2bit (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [3:0] product
);
    // 部分积
    wire pp0_0, pp0_1, pp1_0, pp1_1;
    
    // 计算部分积
    assign pp0_0 = a[0] & b[0];
    assign pp0_1 = a[0] & b[1];
    assign pp1_0 = a[1] & b[0];
    assign pp1_1 = ~(a[1] & b[1]); // Baugh-Wooley算法中符号位取反
    
    // 最终结果计算
    assign product[0] = pp0_0;
    assign product[1] = pp0_1 ^ pp1_0;
    assign product[2] = (pp0_1 & pp1_0) ^ pp1_1 ^ 1'b1; // 添加修正位1
    assign product[3] = (pp0_1 & pp1_0 & pp1_1) | ((pp0_1 & pp1_0) & 1'b1) | (pp1_1 & 1'b1);

endmodule

// 状态寄存器子模块
module state_register (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] next_state,
    output reg  [1:0] current_state
);

    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (rst)
            current_state <= 2'b00;
        else
            current_state <= next_state;
    end

endmodule