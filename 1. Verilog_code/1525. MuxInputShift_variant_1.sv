//SystemVerilog
// IEEE 1364-2005
module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    output [W-1:0] q
);
    // 内部信号声明
    reg [W-1:0] q_reg;
    reg [W-1:0] q_buf1, q_buf2;
    wire [W-1:0] next_q_reg;

    // 组合逻辑部分：计算下一状态
    MuxInputShift_Comb #(.W(W)) comb_logic (
        .sel(sel),
        .d0(d0),
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .q_buf1(q_buf1),
        .q_buf2(q_buf2),
        .next_q_reg(next_q_reg)
    );
    
    // 时序逻辑部分：寄存器更新
    always @(posedge clk) begin
        q_reg <= next_q_reg;
    end
    
    // 缓冲寄存器更新
    always @(posedge clk) begin
        q_buf1 <= q_reg;
        q_buf2 <= q_reg;
    end
    
    // 输出赋值
    assign q = q_reg;
    
endmodule

// 组合逻辑模块
module MuxInputShift_Comb #(parameter W=4) (
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    input [W-1:0] q_buf1, q_buf2,
    output reg [W-1:0] next_q_reg
);
    // 纯组合逻辑实现
    always @(*) begin
        case(sel)
            2'b00: next_q_reg = {q_buf1[W-2:0], d0[0]};
            2'b01: next_q_reg = {q_buf1[W-2:0], d1[0]};
            2'b10: next_q_reg = {d2, q_buf2[W-1:1]};
            2'b11: next_q_reg = d3;
            default: next_q_reg = {W{1'b0}}; // 添加默认情况以避免锁存器
        endcase
    end
    
endmodule