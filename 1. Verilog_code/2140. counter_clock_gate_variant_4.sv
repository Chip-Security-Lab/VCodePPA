//SystemVerilog
module counter_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output wire clk_out
);
    reg [3:0] cnt;
    reg       clk_en;  // 时钟使能信号
    
    // 主计数器逻辑 - 优化比较操作
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'b0;
        else if (cnt >= div_ratio)  // 使用>=替代==，更高效的比较
            cnt <= 4'b0;
        else
            cnt <= cnt + 1'b1;
    end
    
    // 时钟使能信号生成 - 合并零检测逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            clk_en <= 1'b1;  // 复位时启用时钟
        else
            clk_en <= (cnt == 4'h0);  // 仅在计数器为0时使能
    end
    
    // 时钟门控输出
    assign clk_out = clk_in & clk_en;
endmodule