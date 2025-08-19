//SystemVerilog
module gray_clock_divider(
    input clock,
    input reset,
    output [3:0] gray_out
);
    reg [3:0] count;
    wire [3:0] next_count;
    
    // 简化Brent-Kung加法器实现
    // 由于常量优化，p和g可以简化
    wire [3:0] p, g, carry;
    
    // 简化后的传播和生成信号
    assign p[0] = ~count[0];  // count[0] XOR 1 = ~count[0]
    assign p[1] = count[1];   // count[1] XOR 0 = count[1]
    assign p[2] = count[2];   // count[2] XOR 0 = count[2]
    assign p[3] = count[3];   // count[3] XOR 0 = count[3]
    
    assign g[0] = count[0];   // count[0] AND 1 = count[0]
    assign g[1] = 1'b0;       // count[1] AND 0 = 0
    assign g[2] = 1'b0;       // count[2] AND 0 = 0
    assign g[3] = 1'b0;       // count[3] AND 0 = 0
    
    // 简化的进位计算
    assign carry[0] = count[0];
    assign carry[1] = 1'b0;   // 由于g[1]=0，p[1]&g[0]不影响结果
    assign carry[2] = 1'b0;   // 由于g[2]=0，p[2]&carry[1]=0
    assign carry[3] = 1'b0;   // 由于所有高位g=0，进位传播无效
    
    // 简化后的下一状态计算
    assign next_count[0] = ~count[0];        // p[0] XOR 0 = p[0] = ~count[0]
    assign next_count[1] = count[1] ^ count[0]; // p[1] XOR carry[0]
    assign next_count[2] = count[2];         // p[2] XOR 0 = count[2]
    assign next_count[3] = count[3];         // p[3] XOR 0 = count[3]
    
    // 使用非阻塞赋值更新计数器
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0000;
        else
            count <= next_count;
    end
    
    // 格雷码输出计算
    assign gray_out = {count[3], count[3]^count[2], count[2]^count[1], count[1]^count[0]};
endmodule