//SystemVerilog
//IEEE 1364-2005
module dual_cnt_div #(parameter DIV1=3, DIV2=5) (
    input wire clk,
    input wire rst_n,
    input wire sel,
    input wire valid_in,
    output wire valid_out,
    output reg clk_out
);

// 计数器寄存器
reg [3:0] cnt1, cnt2;
reg sel_pipe1, sel_pipe2;
reg valid_pipe1, valid_pipe2;

// 计数器零检测的提前寄存
reg cnt1_will_be_zero, cnt2_will_be_zero;

// 计数器逻辑 - 移动了寄存器以优化关键路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt1 <= 4'b0;
        cnt2 <= 4'b0;
        cnt1_will_be_zero <= 1'b0;
        cnt2_will_be_zero <= 1'b0;
        valid_pipe1 <= 1'b0;
        sel_pipe1 <= 1'b0;
    end
    else begin
        if (valid_in) begin
            // 计算下一个计数器值
            cnt1 <= (cnt1 == DIV1-1) ? 0 : cnt1 + 1;
            cnt2 <= (cnt2 == DIV2-1) ? 0 : cnt2 + 1;
            
            // 提前检测下一个周期是否会为零
            cnt1_will_be_zero <= (cnt1 == DIV1-1);
            cnt2_will_be_zero <= (cnt2 == DIV2-1);
            
            valid_pipe1 <= valid_in;
            sel_pipe1 <= sel;
        end
    end
end

// 第二级流水线 - 传递控制信号和计算结果
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_pipe2 <= 1'b0;
        sel_pipe2 <= 1'b0;
    end
    else begin
        if (valid_pipe1) begin
            valid_pipe2 <= valid_pipe1;
            sel_pipe2 <= sel_pipe1;
        end
    end
end

// 输出生成 - 使用提前计算的零检测结果
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_out <= 1'b0;
    end
    else begin
        if (valid_pipe2) begin
            clk_out <= sel_pipe2 ? cnt2_will_be_zero : cnt1_will_be_zero;
        end
    end
end

// 输出有效信号
assign valid_out = valid_pipe2;

endmodule