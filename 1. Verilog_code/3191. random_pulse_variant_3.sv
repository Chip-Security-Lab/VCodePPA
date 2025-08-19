//SystemVerilog
module random_pulse #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B
)(
    input clk,
    input rst,
    output reg pulse
);

reg [LFSR_WIDTH-1:0] lfsr;
reg [LFSR_WIDTH-1:0] lfsr_next;
reg pulse_next;

// 分解复杂的条件表达式为中间变量
wire feedback_bit;
wire threshold_check;

// 计算LFSR的反馈位
assign feedback_bit = lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[0];

// 计算下一个LFSR状态
always @(*) begin
    lfsr_next = {lfsr[LFSR_WIDTH-2:0], feedback_bit};
end

// 使用分级条件结构检查阈值
assign threshold_check = (lfsr_next < 8'h20);

always @(*) begin
    pulse_next = threshold_check;
end

// 时序逻辑不变
always @(posedge clk or posedge rst) begin
    if (rst) begin
        lfsr <= SEED;
        pulse <= 1'b0;
    end else begin
        lfsr <= lfsr_next;
        pulse <= pulse_next;
    end
end

endmodule