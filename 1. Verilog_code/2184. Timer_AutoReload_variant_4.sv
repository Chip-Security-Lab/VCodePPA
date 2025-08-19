//SystemVerilog
module Timer_AutoReload #(parameter VAL=255) (
    input clk, en, rst,
    output reg alarm
);
    reg [7:0] cnt;
    reg [7:0] next_cnt;
    
    // 跳跃进位加法器实现
    wire [7:0] minusOne = 8'hFF; // -1的补码表示
    wire [3:0] p, g; // 生成和传播信号
    wire [3:0] carry; // 跳跃进位信号
    
    // 生成传播和生成信号
    assign p[0] = cnt[1:0] != 2'b00;
    assign p[1] = cnt[3:2] != 2'b00;
    assign p[2] = cnt[5:4] != 2'b00;
    assign p[3] = cnt[7:6] != 2'b00;
    
    assign g[0] = cnt[1:0] == 2'b01;
    assign g[1] = cnt[3:2] == 2'b01;
    assign g[2] = cnt[5:4] == 2'b01;
    assign g[3] = cnt[7:6] == 2'b01;
    
    // 计算跳跃进位
    assign carry[0] = g[0] | (p[0] & 1'b1); // 输入进位为1
    assign carry[1] = g[1] | (p[1] & carry[0]);
    assign carry[2] = g[2] | (p[2] & carry[1]);
    assign carry[3] = g[3] | (p[3] & carry[2]);
    
    // 计算下一个计数值
    always @(*) begin
        if (cnt == 0) begin
            next_cnt = VAL;
        end else begin
            // 使用跳跃进位加法器实现减一操作
            next_cnt[1:0] = cnt[1:0] + 2'b11; // +(-1) 在该位
            next_cnt[3:2] = cnt[3:2] + {2{carry[0]}} + 2'b11;
            next_cnt[5:4] = cnt[5:4] + {2{carry[1]}} + 2'b11;
            next_cnt[7:6] = cnt[7:6] + {2{carry[2]}} + 2'b11;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= VAL;
            alarm <= 0;
        end else if (en) begin
            alarm <= (cnt == 0);
            cnt <= next_cnt;
        end
    end
endmodule