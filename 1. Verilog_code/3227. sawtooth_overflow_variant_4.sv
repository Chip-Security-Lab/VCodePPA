//SystemVerilog
module sawtooth_overflow(
    input clk,
    input rst,
    input [7:0] increment,
    output reg [7:0] sawtooth,
    output reg overflow
);
    // 内部信号声明
    reg [8:0] next_value; // 用于计算下一个值的9位临时变量

    // 计算逻辑 - 处理下一个值的计算
    always @(*) begin
        next_value = sawtooth + increment; // 计算下一个值
    end

    // 计数器更新逻辑 - 更新sawtooth值
    always @(posedge clk) begin
        if (rst) begin
            sawtooth <= 8'd0;
        end else begin
            sawtooth <= next_value[7:0]; // 更新低8位作为sawtooth输出
        end
    end

    // 溢出标志处理逻辑
    always @(posedge clk) begin
        if (rst) begin
            overflow <= 1'b0;
        end else begin
            overflow <= next_value[8]; // 最高位作为溢出标志
        end
    end
endmodule