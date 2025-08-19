module NewtonDiv(
    input clk, [15:0] N, D,
    output reg [15:0] Q
);
    reg [15:0] x0;
    
    // 使用固定初始值而不是依赖输入值D
    initial x0 = 16'h0100;
    
    always @(posedge clk) begin
        // 添加除零保护
        if (D != 0) begin
            // 牛顿迭代法: x_{n+1} = x_n * (2 - D * x_n)
            x0 <= ((x0 * (16'h0002 - ((D * x0) >> 16))));
            Q <= ((N * x0) >> 8);
        end else begin
            // 处理除零情况 - 设置为最大值
            Q <= 16'hFFFF;
        end
    end
endmodule