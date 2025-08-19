//SystemVerilog
`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// 顶层模块 - T触发器脉冲控制 (Valid-Ready握手接口)
//-----------------------------------------------------------------------------
module tff_pulse (
    input  wire        clk,         // 时钟信号
    input  wire        rstn,        // 低电平有效的复位信号
    input  wire        t,           // T触发器的输入信号
    input  wire        t_valid,     // 输入数据有效信号
    output wire        t_ready,     // 输入数据就绪信号
    output wire        q,           // T触发器的输出
    output wire        q_valid,     // 输出数据有效信号
    input  wire        q_ready      // 输出数据就绪信号
);

    // 内部连线
    wire toggle_enable;      // 翻转使能信号
    wire next_state;         // 下一状态信号
    wire handshake_in;       // 输入握手完成信号
    wire handshake_out;      // 输出握手完成信号
    
    // 握手信号生成
    assign handshake_in  = t_valid & t_ready;
    assign handshake_out = q_valid & q_ready;
    assign t_ready = !q_valid || q_ready;  // 当输出未准备好或者下游已准备好接收时，可以接收新输入
    
    // 实例化子模块
    tff_control_logic u_control (
        .t_in           (t),
        .handshake_in   (handshake_in),
        .current_state  (q),
        .toggle_enable  (toggle_enable),
        .next_state     (next_state)
    );
    
    tff_state_register u_register (
        .clk            (clk),
        .rstn           (rstn),
        .toggle_enable  (toggle_enable),
        .handshake_in   (handshake_in),
        .handshake_out  (handshake_out),
        .next_state     (next_state),
        .q_out          (q),
        .q_valid        (q_valid)
    );

endmodule

//-----------------------------------------------------------------------------
// 子模块 - 控制逻辑单元
//-----------------------------------------------------------------------------
module tff_control_logic (
    input  wire t_in,           // T输入信号
    input  wire handshake_in,   // 输入握手完成信号
    input  wire current_state,  // 当前状态
    output wire toggle_enable,  // 是否允许状态翻转
    output wire next_state      // 计算的下一状态
);

    // 控制逻辑实现
    assign toggle_enable = t_in & handshake_in;  // 当t有效且握手完成时允许翻转
    assign next_state = toggle_enable ? ~current_state : current_state;  // 计算下一状态

endmodule

//-----------------------------------------------------------------------------
// 子模块 - 状态寄存器单元
//-----------------------------------------------------------------------------
module tff_state_register (
    input  wire clk,           // 时钟信号
    input  wire rstn,          // 低电平有效的复位信号
    input  wire toggle_enable, // 翻转使能
    input  wire handshake_in,  // 输入握手完成信号
    input  wire handshake_out, // 输出握手完成信号
    input  wire next_state,    // 下一状态输入
    output reg  q_out,         // 寄存器输出
    output reg  q_valid        // 输出数据有效信号
);

    // 状态寄存器实现
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_out <= 1'b0;     // 异步复位
            q_valid <= 1'b0;   // 复位时输出无效
        end
        else begin
            if (handshake_in) begin
                q_out <= next_state;  // 输入握手成功时更新状态
                q_valid <= 1'b1;      // 设置输出有效
            end
            else if (handshake_out) begin
                q_valid <= 1'b0;      // 输出握手成功后清除有效标志
            end
        end
    end

endmodule