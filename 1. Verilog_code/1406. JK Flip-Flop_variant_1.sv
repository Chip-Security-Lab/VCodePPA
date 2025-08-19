//SystemVerilog
// JK触发器顶层模块 - IEEE 1364-2005 标准
module jk_flip_flop (
    input  wire clk,
    input  wire j,
    input  wire k,
    output reg  q
);
    
    // 内部信号
    wire [1:0] jk;
    wire       set_value;
    wire       next_q;
    
    // 信号组合
    assign jk = {j, k};
    
    // 子模块实例化
    jk_decoder jk_decoder_inst (
        .jk        (jk),
        .current_q (q),
        .next_q    (next_q)
    );
    
    // 状态更新子模块
    state_update state_update_inst (
        .clk     (clk),
        .next_q  (next_q),
        .q       (q)
    );
    
endmodule

// JK输入解码器子模块
module jk_decoder (
    input  wire [1:0] jk,
    input  wire       current_q,
    output wire       next_q
);
    
    // JK输入解码逻辑
    reg next_q_reg;
    
    always @(*) begin
        case (jk)
            2'b00  : next_q_reg = current_q;    // 保持当前状态
            2'b01  : next_q_reg = 1'b0;         // 复位操作
            2'b10  : next_q_reg = 1'b1;         // 置位操作
            2'b11  : next_q_reg = ~current_q;   // 翻转操作
            default: next_q_reg = current_q;    // 默认保持
        endcase
    end
    
    assign next_q = next_q_reg;
    
endmodule

// 状态更新子模块
module state_update (
    input  wire clk,
    input  wire next_q,
    output reg  q
);
    
    // 时钟上升沿更新状态
    always @(posedge clk) begin
        q <= next_q;
    end
    
endmodule