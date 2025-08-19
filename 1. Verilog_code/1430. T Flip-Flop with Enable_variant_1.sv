//SystemVerilog

// 顶层模块
module t_ff_enable (
    input wire clk,
    input wire en,
    input wire t,
    output wire q
);
    // 内部连线
    wire toggle_condition;
    wire next_q;
    wire curr_q;
    
    // 实例化子模块
    toggle_condition_detector toggle_detect (
        .en(en),
        .t(t),
        .curr_q(curr_q),
        .toggle_condition(toggle_condition),
        .next_q(next_q)
    );
    
    state_register state_reg (
        .clk(clk),
        .next_q(next_q),
        .curr_q(curr_q)
    );
    
    // 输出赋值
    assign q = curr_q;
    
endmodule

// 子模块1: 切换条件检测器
module toggle_condition_detector (
    input wire en,
    input wire t,
    input wire curr_q,
    output wire toggle_condition,
    output wire next_q
);
    // 判断是否需要切换输出状态
    assign toggle_condition = en & t;
    
    // 计算下一个状态值
    assign next_q = toggle_condition ? ~curr_q : curr_q;
    
endmodule

// 子模块2: 状态寄存器
module state_register (
    input wire clk,
    input wire next_q,
    output reg curr_q
);
    // 状态寄存器，在时钟上升沿更新状态
    always @(posedge clk) begin
        curr_q <= next_q;
    end
    
endmodule