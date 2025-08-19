//SystemVerilog
module sync_shift_rst_with_adder #(parameter DEPTH=4) (
    input wire clk,
    input wire rst,
    input wire serial_in,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output reg [DEPTH-1:0] shift_reg,
    output wire [8:0] sum_out
);
    // 第一个移位寄存器级别的处理
    always @(posedge clk) begin
        if (rst)
            shift_reg[0] <= 1'b0;
        else
            shift_reg[0] <= serial_in;
    end

    // 为每个移位寄存器级别生成单独的always块
    genvar i;
    generate
        for (i = 1; i < DEPTH; i = i + 1) begin : shift_stage
            always @(posedge clk) begin
                if (rst)
                    shift_reg[i] <= 1'b0;
                else
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    endgenerate
    
    // 添加Han-Carlson加法器
    han_carlson_adder_8bit han_carlson_inst (
        .a(a_in),
        .b(b_in),
        .sum(sum_out)
    );
endmodule

// 8位Han-Carlson加法器模块
module han_carlson_adder_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [8:0] sum
);
    // 第一阶段：生成传播和生成信号
    wire [7:0] p, g;
    
    // 生成初始传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 第二阶段处理 - 偶数位前缀计算
    // 偶数位初始信号提取
    wire [3:0] even_p, even_g;
    assign even_p[0] = p[0];
    assign even_g[0] = g[0];
    assign even_p[1] = p[2];
    assign even_g[1] = g[2];
    assign even_p[2] = p[4];
    assign even_g[2] = g[4];
    assign even_p[3] = p[6];
    assign even_g[3] = g[6];
    
    // 偶数位前缀计算 - 第一级
    wire [3:0] p_lvl1, g_lvl1;
    assign p_lvl1[0] = even_p[0];
    assign g_lvl1[0] = even_g[0];
    
    assign p_lvl1[1] = even_p[1] & even_p[0];
    assign g_lvl1[1] = even_g[1] | (even_p[1] & even_g[0]);
    
    assign p_lvl1[2] = even_p[2] & even_p[1];
    assign g_lvl1[2] = even_g[2] | (even_p[2] & even_g[1]);
    
    assign p_lvl1[3] = even_p[3] & even_p[2];
    assign g_lvl1[3] = even_g[3] | (even_p[3] & even_g[2]);
    
    // 偶数位前缀计算 - 第二级
    wire [3:0] p_lvl2, g_lvl2;
    assign p_lvl2[0] = p_lvl1[0];
    assign g_lvl2[0] = g_lvl1[0];
    
    assign p_lvl2[1] = p_lvl1[1];
    assign g_lvl2[1] = g_lvl1[1];
    
    assign p_lvl2[2] = p_lvl1[2] & p_lvl1[0];
    assign g_lvl2[2] = g_lvl1[2] | (p_lvl1[2] & g_lvl1[0]);
    
    assign p_lvl2[3] = p_lvl1[3] & p_lvl1[1];
    assign g_lvl2[3] = g_lvl1[3] | (p_lvl1[3] & g_lvl1[1]);
    
    // 最终偶数位前缀结果
    wire [7:0] pp, gg;
    
    // 偶数位结果分配
    assign pp[0] = p_lvl2[0];
    assign gg[0] = g_lvl2[0];
    assign pp[2] = p_lvl2[1];
    assign gg[2] = g_lvl2[1];
    assign pp[4] = p_lvl2[2];
    assign gg[4] = g_lvl2[2];
    assign pp[6] = p_lvl2[3];
    assign gg[6] = g_lvl2[3];
    
    // 奇数位处理 - 基于前一个偶数位
    assign pp[1] = p[1] & pp[0];
    assign gg[1] = g[1] | (p[1] & gg[0]);
    
    assign pp[3] = p[3] & pp[2];
    assign gg[3] = g[3] | (p[3] & gg[2]);
    
    assign pp[5] = p[5] & pp[4];
    assign gg[5] = g[5] | (p[5] & gg[4]);
    
    assign pp[7] = p[7] & pp[6];
    assign gg[7] = g[7] | (p[7] & gg[6]);
    
    // 进位信号生成
    wire [7:0] carry;
    assign carry = gg;
    
    // 最终和计算
    assign sum[0] = p[0];
    
    // 低位和计算（1-3位）
    assign sum[1] = p[1] ^ carry[0];
    assign sum[2] = p[2] ^ carry[1];
    assign sum[3] = p[3] ^ carry[2];
    
    // 高位和计算（4-7位）
    assign sum[4] = p[4] ^ carry[3];
    assign sum[5] = p[5] ^ carry[4];
    assign sum[6] = p[6] ^ carry[5];
    assign sum[7] = p[7] ^ carry[6];
    
    // 最高位进位
    wire carry_out;
    assign carry_out = g[7] | (p[7] & carry[6]);
    assign sum[8] = carry_out;
endmodule