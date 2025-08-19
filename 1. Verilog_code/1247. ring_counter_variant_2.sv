//SystemVerilog
module ring_counter (
    input wire clock, reset,
    input wire enable,  // 添加使能信号以控制流水线
    output reg [7:0] ring_out  // 更改输出名称以表明这是最终输出
);
    // 流水线寄存器
    reg [7:0] ring_stage1;
    reg [7:0] ring_stage2;
    reg valid_stage1, valid_stage2;

    // 第一级流水线 - 初始化或移位
    always @(posedge clock) begin
        if (reset) begin
            ring_stage1 <= 8'b10000000;
            valid_stage1 <= 1'b1;
        end
        else if (enable) begin
            ring_stage1 <= {ring_out[0], ring_out[7:1]};
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end

    // 第二级流水线 - 中间处理
    always @(posedge clock) begin
        if (reset) begin
            ring_stage2 <= 8'b10000000;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            ring_stage2 <= ring_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出级 - 最终结果
    always @(posedge clock) begin
        if (reset) begin
            ring_out <= 8'b10000000;
        end
        else if (enable && valid_stage2) begin
            ring_out <= ring_stage2;
        end
    end
endmodule