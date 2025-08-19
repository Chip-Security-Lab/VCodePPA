//SystemVerilog
module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    output reg clk_out
);
    reg [5:0] counter;
    reg [3:0] mod_counter;
    reg [3:0] divisor;
    
    // Kogge-Stone 6位加法器实现
    wire [5:0] counter_next;
    
    // 生成(G)和传播(P)信号
    wire [5:0] G, P;
    assign G = counter & 6'd1; // 生成信号
    assign P = counter ^ 6'd1; // 传播信号
    
    // 第一级：前缀计算
    wire [5:0] G_1, P_1;
    assign G_1[0] = G[0];
    assign P_1[0] = P[0];
    
    assign G_1[1] = G[1] | (P[1] & G[0]);
    assign P_1[1] = P[1] & P[0];
    
    assign G_1[2] = G[2];
    assign P_1[2] = P[2];
    
    assign G_1[3] = G[3] | (P[3] & G[2]);
    assign P_1[3] = P[3] & P[2];
    
    assign G_1[4] = G[4];
    assign P_1[4] = P[4];
    
    assign G_1[5] = G[5] | (P[5] & G[4]);
    assign P_1[5] = P[5] & P[4];
    
    // 第二级：前缀计算
    wire [5:0] G_2, P_2;
    assign G_2[0] = G_1[0];
    assign P_2[0] = P_1[0];
    
    assign G_2[1] = G_1[1];
    assign P_2[1] = P_1[1];
    
    assign G_2[2] = G_1[2] | (P_1[2] & G_1[0]);
    assign P_2[2] = P_1[2] & P_1[0];
    
    assign G_2[3] = G_1[3] | (P_1[3] & G_1[1]);
    assign P_2[3] = P_1[3] & P_1[1];
    
    assign G_2[4] = G_1[4] | (P_1[4] & G_1[2]);
    assign P_2[4] = P_1[4] & P_1[2];
    
    assign G_2[5] = G_1[5] | (P_1[5] & G_1[3]);
    assign P_2[5] = P_1[5] & P_1[3];
    
    // 第三级：前缀计算
    wire [5:0] G_3, P_3;
    assign G_3[0] = G_2[0];
    assign P_3[0] = P_2[0];
    
    assign G_3[1] = G_2[1];
    assign P_3[1] = P_2[1];
    
    assign G_3[2] = G_2[2];
    assign P_3[2] = P_2[2];
    
    assign G_3[3] = G_2[3];
    assign P_3[3] = P_2[3];
    
    assign G_3[4] = G_2[4] | (P_2[4] & G_2[0]);
    assign P_3[4] = P_2[4] & P_2[0];
    
    assign G_3[5] = G_2[5] | (P_2[5] & G_2[1]);
    assign P_3[5] = P_2[5] & P_2[1];
    
    // 计算进位
    wire [5:0] carry;
    assign carry[0] = 1'b0; // 初始进位为0
    assign carry[1] = G_3[0];
    assign carry[2] = G_3[1];
    assign carry[3] = G_3[2];
    assign carry[4] = G_3[3];
    assign carry[5] = G_3[4];
    
    // 计算最终结果
    assign counter_next = P ^ carry;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 6'd0;
            mod_counter <= 4'd0;
            divisor <= 4'd8;
            clk_out <= 1'b0;
        end else begin
            // 优化mod_counter逻辑
            mod_counter <= mod_counter + 4'd1;
            
            // 简化除数计算逻辑
            if (mod_counter == 4'd15)
                divisor <= 4'd8 + (modulation[0] & counter[5]);
                
            // 简化计数器重置与时钟输出逻辑
            if (counter >= {2'b00, divisor}) begin
                counter <= 6'd0;
                clk_out <= ~clk_out;
            end else
                counter <= counter_next;
        end
    end
endmodule