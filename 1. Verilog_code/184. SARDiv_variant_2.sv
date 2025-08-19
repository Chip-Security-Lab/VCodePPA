//SystemVerilog
module SARDiv(
    input clk, start,
    input [7:0] D, d,
    output reg [7:0] q,
    output reg done,
    output reg req,  // 请求信号
    input ack        // 应答信号
);
    reg [7:0] rem;
    reg [3:0] bit_cnt;
    reg [7:0] lut[0:255]; // 查找表
    wire [7:0] shifted_rem = rem << 1; // 预计算移位结果

    initial begin
        // 初始化查找表， lut[a] = 0 - a
        integer i;
        for (i = 0; i < 256; i = i + 1) begin
            lut[i] = 8'b0 - i; // 计算查找表的值
        end
    end

    always @(posedge clk) begin
        if (start) begin
            rem <= D;
            bit_cnt <= 7;
            q <= 0;
            done <= 0;
            req <= 1; // 开始请求
        end else if (req && ack) begin
            // 处理移位和查找表减法
            if (shifted_rem >= d && d != 0) begin
                rem <= shifted_rem + lut[d]; // 使用查找表进行减法
                q[bit_cnt] <= 1'b1;
            end else begin
                rem <= shifted_rem;
            end
            
            // 更新位计数器和完成标志
            if (bit_cnt == 0) begin
                done <= 1;
                req <= 0; // 完成后不再请求
            end else begin
                bit_cnt <= bit_cnt - 1;
            end
        end
    end
endmodule