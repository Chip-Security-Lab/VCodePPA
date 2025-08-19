module SARDiv(
    input clk, start,
    input [7:0] D, d,
    output reg [7:0] q,
    output reg done
);
    reg [7:0] rem;
    reg [3:0] bit_cnt;
    wire [7:0] shifted_rem = rem << 1; // 预计算移位结果
    
    always @(posedge clk) begin
        if(start) begin
            rem <= D;
            bit_cnt <= 7;
            q <= 0;
            done <= 0;
        end else if(bit_cnt <= 7) begin
            // 处理移位和减法
            if(shifted_rem >= d && d != 0) begin
                rem <= shifted_rem - d;
                q[bit_cnt] <= 1'b1;
            end else begin
                rem <= shifted_rem;
            end
            
            // 更新位计数器和完成标志
            if(bit_cnt == 0)
                done <= 1;
            else
                bit_cnt <= bit_cnt - 1;
        end
    end
endmodule