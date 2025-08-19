//SystemVerilog
module SARDiv(
    input clk, start,
    input [7:0] D, d,
    output reg [7:0] q,
    output reg done
);
    reg [7:0] rem;
    reg [3:0] bit_cnt;
    wire [7:0] shifted_rem = rem << 1; // 预计算移位结果

    // 曼彻斯特进位链加法器实现
    wire [7:0] carry;
    wire [7:0] sum;
    wire [7:0] d_comp = ~d + 1'b1; // 求d的二进制补码
    wire sub_sel = (shifted_rem >= d && d != 0); // 判断是否需要减法

    // 曼彻斯特进位链加法器
    assign {carry, sum} = shifted_rem + (sub_sel ? d_comp : 8'b0);

    always @(posedge clk) begin
        if(start) begin
            rem <= D;
            bit_cnt <= 7;
            q <= 0;
            done <= 0;
        end else if(bit_cnt <= 7) begin
            // 使用曼彻斯特进位链加法器结果
            rem <= sub_sel ? sum : shifted_rem;
            q[bit_cnt] <= sub_sel;

            // 更新位计数器和完成标志
            if(bit_cnt == 0)
                done <= 1;
            else
                bit_cnt <= bit_cnt - 1;
        end
    end
endmodule