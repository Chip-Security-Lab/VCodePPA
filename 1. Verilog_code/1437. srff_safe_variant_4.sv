//SystemVerilog
module srff_safe (
    input wire clk,
    input wire s,
    input wire r,
    input wire valid_in,    // 输入有效信号
    output reg q,
    output reg valid_out    // 输出有效信号
);

// 流水线阶段1：输入寄存器
reg s_stage1, r_stage1;
reg valid_stage1;

// 流水线阶段2：中间处理
reg s_stage2, r_stage2;
reg valid_stage2;

// 流水线阶段3：状态更新
reg next_q;
reg valid_stage3;

// 阶段1：输入寄存
always @(posedge clk) begin
    s_stage1 <= s;
    r_stage1 <= r;
    valid_stage1 <= valid_in;
end

// 阶段2：状态计算
always @(posedge clk) begin
    s_stage2 <= s_stage1;
    r_stage2 <= r_stage1;
    valid_stage2 <= valid_stage1;
end

// 阶段3：确定下一状态
always @(posedge clk) begin
    case ({s_stage2, r_stage2})
        2'b11: next_q <= 1'bx; // 非法状态处理
        2'b10: next_q <= 1'b1; // s=1, r=0
        2'b01: next_q <= 1'b0; // s=0, r=1
        2'b00: next_q <= q;    // 保持当前状态
    endcase
    valid_stage3 <= valid_stage2;
end

// 最终输出
always @(posedge clk) begin
    q <= next_q;
    valid_out <= valid_stage3;
end

endmodule