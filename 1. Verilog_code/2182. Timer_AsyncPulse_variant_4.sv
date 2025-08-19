//SystemVerilog
module Timer_AsyncPulse (
    input clk, rst, start,
    output reg pulse
);
    reg [3:0] cnt;
    reg start_r;
    wire [3:0] next_cnt;
    wire incr;
    
    // 寄存输入信号
    always @(posedge clk or posedge rst) begin
        if (rst) 
            start_r <= 1'b0;
        else 
            start_r <= start;
    end
    
    // 计数器使能信号
    assign incr = (cnt < 15) & start_r;
    
    // 曼彻斯特进位链加法器实现
    wire [3:0] p, g;
    wire [3:0] c;
    
    // 生成传播(p)信号
    assign p[0] = cnt[0];
    assign p[1] = cnt[1];
    assign p[2] = cnt[2];
    assign p[3] = cnt[3];
    
    // 生成生成(g)信号
    assign g[0] = 1'b0;
    assign g[1] = cnt[0] & incr;
    assign g[2] = cnt[1] & p[1];
    assign g[3] = cnt[2] & p[2];
    
    // 计算进位链
    assign c[0] = incr;
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);
    
    // 计算下一个计数值
    assign next_cnt[0] = cnt[0] ^ incr;
    assign next_cnt[1] = cnt[1] ^ c[0];
    assign next_cnt[2] = cnt[2] ^ c[1];
    assign next_cnt[3] = cnt[3] ^ c[2];
    
    // 计数器更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) 
            cnt <= 4'b0;
        else if (start_r) 
            cnt <= next_cnt;
    end
    
    // 脉冲输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) 
            pulse <= 1'b0;
        else
            pulse <= (next_cnt == 4'd15);
    end
endmodule