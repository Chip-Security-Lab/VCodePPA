module WindowAvgRecovery #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    integer i;  // 使用integer进行迭代

    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位时清零
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= 0;
            end
            dout <= 0;
        end else begin
            // 更新buffer，修复错误的数组赋值
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= din;
            
            // 计算平均值
            dout <= (buffer[0] + buffer[1] + buffer[2] + buffer[3]) >> 2;
        end
    end
endmodule