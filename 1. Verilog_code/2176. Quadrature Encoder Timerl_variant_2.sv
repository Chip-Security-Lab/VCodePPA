//SystemVerilog
module quad_encoder_timer (
    input wire clk, rst, quad_a, quad_b, timer_en,
    output reg [15:0] position,
    output reg [31:0] timer
);
    reg a_prev, b_prev;
    wire count_up, count_down;
    
    // 同步处理前一状态
    always @(posedge clk) begin
        if (rst) begin 
            a_prev <= 1'b0; 
            b_prev <= 1'b0; 
        end
        else begin 
            a_prev <= quad_a; 
            b_prev <= quad_b; 
        end
    end
    
    // 计算方向信号
    assign count_up = quad_a ^ b_prev;
    assign count_down = quad_b ^ a_prev;
    
    // 位置计数器 - 使用if-else结构
    always @(posedge clk) begin
        if (rst) begin
            position <= 16'h0000;
        end
        else if (quad_a != a_prev || quad_b != b_prev) begin
            if (count_up) begin
                position <= position + 1'b1;
            end
            else if (count_down) begin
                position <= position - 1'b1;
            end
            // 其他情况保持原值
        end
    end
    
    // 定时器计数 - 使用先行进位加法器算法
    wire [31:0] timer_next;
    wire [31:0] timer_inc;
    
    // 定义生成(G)和传播(P)信号
    wire [31:0] G, P;
    wire [31:0] C; // 进位信号
    
    // 增量值
    assign timer_inc = timer_en ? 32'h1 : 32'h0;
    
    // 生成生成和传播信号
    assign G = timer & timer_inc;
    assign P = timer | timer_inc;
    
    // 4位分组的先行进位逻辑
    wire [7:0] G4, P4;
    wire [7:0] C4;
    
    // 第一级先行进位计算
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: cla_level1
            assign G4[i] = G[i*4+3] | 
                          (P[i*4+3] & G[i*4+2]) | 
                          (P[i*4+3] & P[i*4+2] & G[i*4+1]) | 
                          (P[i*4+3] & P[i*4+2] & P[i*4+1] & G[i*4]);
            
            assign P4[i] = P[i*4+3] & P[i*4+2] & P[i*4+1] & P[i*4];
        end
    endgenerate
    
    // 第二级先行进位计算
    assign C4[0] = 1'b0; // 初始进位为0
    
    genvar j;
    generate
        for (j = 1; j < 8; j = j + 1) begin: cla_level2
            assign C4[j] = G4[j-1] | (P4[j-1] & C4[j-1]);
        end
    endgenerate
    
    // 最后计算每一位的进位
    generate
        for (i = 0; i < 8; i = i + 1) begin: cla_level3
            // 每个4位组的第一位
            assign C[i*4] = C4[i];
            // 其余位的进位计算
            assign C[i*4+1] = G[i*4] | (P[i*4] & C[i*4]);
            assign C[i*4+2] = G[i*4+1] | (P[i*4+1] & G[i*4]) | (P[i*4+1] & P[i*4] & C[i*4]);
            assign C[i*4+3] = G[i*4+2] | (P[i*4+2] & G[i*4+1]) | 
                            (P[i*4+2] & P[i*4+1] & G[i*4]) | 
                            (P[i*4+2] & P[i*4+1] & P[i*4] & C[i*4]);
        end
    endgenerate
    
    // 计算和
    assign timer_next = timer ^ timer_inc ^ {C[30:0], 1'b0};
    
    // 更新定时器
    always @(posedge clk) begin
        if (rst) begin
            timer <= 32'h0;
        end
        else begin
            timer <= timer_next;
        end
    end
endmodule