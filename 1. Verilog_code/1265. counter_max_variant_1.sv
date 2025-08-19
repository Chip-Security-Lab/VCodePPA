//SystemVerilog
module counter_max #(
    parameter MAX = 15
)(
    input  wire                  clk,      // 系统时钟
    input  wire                  rst,      // 复位信号
    output reg  [$clog2(MAX):0]  cnt       // 计数输出
);

    // 内部流水线信号
    reg [$clog2(MAX):0] cnt_next;
    reg                 cnt_at_max;
    
    // 第一级流水线：复位处理
    always @(posedge clk) begin
        if (rst) begin
            cnt_at_max <= 1'b0;
            cnt_next <= 'b0;
            cnt <= 'b0;
        end
    end
    
    // 第二级流水线：计算是否达到最大值
    always @(posedge clk) begin
        if (!rst) begin
            cnt_at_max <= (cnt == MAX);
        end
    end
    
    // 第三级流水线：计算下一个计数值
    always @(posedge clk) begin
        if (!rst) begin
            cnt_next <= cnt + 1'b1;
        end
    end
    
    // 第四级流水线：产生最终输出
    always @(posedge clk) begin
        if (!rst) begin
            cnt <= cnt_at_max ? MAX : cnt_next;
        end
    end

endmodule