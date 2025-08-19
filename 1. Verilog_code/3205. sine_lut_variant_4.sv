//SystemVerilog
module sine_lut(
    input clk,
    input rst_n,
    input [3:0] addr_step,
    output reg [7:0] sine_out
);
    reg [7:0] addr;
    reg [7:0] sine_table [0:15];
    wire [7:0] addr_next;
    
    // Han-Carlson 加法器实现
    wire [7:0] p, g;  // 传播和生成信号
    wire [7:0] pp, gg; // 第一级预处理后的信号
    wire [7:0] p_out, g_out; // 最终输出信号
    
    // 扩展addr_step为8位
    wire [7:0] addr_step_ext;
    assign addr_step_ext = {4'b0000, addr_step};
    
    // 生成初始的传播和生成信号
    assign p = addr | addr_step_ext;
    assign g = addr & addr_step_ext;
    
    // 第一级预处理
    assign pp[0] = p[0];
    assign gg[0] = g[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin: pre_processing
            assign pp[i] = p[i];
            assign gg[i] = g[i];
        end
    endgenerate
    
    // Han-Carlson树状结构 - 奇数位
    wire [7:0] p_odd_1, g_odd_1;
    
    generate
        for (i = 1; i < 8; i = i + 2) begin: hc_odd_level1
            assign p_odd_1[i] = pp[i] & pp[i-1];
            assign g_odd_1[i] = gg[i] | (pp[i] & gg[i-1]);
        end
    endgenerate
    
    // Han-Carlson树状结构 - 偶数位第一级
    wire [7:0] p_even_1, g_even_1;
    
    generate
        for (i = 2; i < 8; i = i + 2) begin: hc_even_level1
            assign p_even_1[i] = pp[i] & pp[i-1];
            assign g_even_1[i] = gg[i] | (pp[i] & gg[i-1]);
        end
    endgenerate
    
    // Han-Carlson树状结构 - 奇数位第二级
    wire [7:0] p_odd_2, g_odd_2;
    
    generate
        for (i = 3; i < 8; i = i + 2) begin: hc_odd_level2
            assign p_odd_2[i] = p_odd_1[i] & p_odd_1[i-2];
            assign g_odd_2[i] = g_odd_1[i] | (p_odd_1[i] & g_odd_1[i-2]);
        end
    endgenerate
    
    // 最终结果组装
    assign p_out[0] = pp[0];
    assign g_out[0] = gg[0];
    
    assign p_out[1] = p_odd_1[1];
    assign g_out[1] = g_odd_1[1];
    
    assign p_out[2] = p_even_1[2];
    assign g_out[2] = g_even_1[2];
    
    generate
        for (i = 3; i < 8; i = i + 2) begin: final_odd
            assign p_out[i] = p_odd_2[i];
            assign g_out[i] = g_odd_2[i];
        end
        
        for (i = 4; i < 8; i = i + 2) begin: final_even
            assign p_out[i] = p_even_1[i] & p_odd_1[i-1];
            assign g_out[i] = g_even_1[i] | (p_even_1[i] & g_odd_1[i-1]);
        end
    endgenerate
    
    // 计算进位
    wire [7:0] carry;
    assign carry[0] = g_out[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin: carry_gen
            assign carry[i] = g_out[i] | (p_out[i] & carry[i-1]);
        end
    endgenerate
    
    // 计算和
    assign addr_next[0] = addr[0] ^ addr_step_ext[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin: sum_gen
            assign addr_next[i] = addr[i] ^ addr_step_ext[i] ^ carry[i-1];
        end
    endgenerate
    
    initial begin
        sine_table[0] = 8'd128;
        sine_table[1] = 8'd176;
        sine_table[2] = 8'd218;
        sine_table[3] = 8'd245;
        sine_table[4] = 8'd255;
        sine_table[5] = 8'd245;
        sine_table[6] = 8'd218;
        sine_table[7] = 8'd176;
        sine_table[8] = 8'd128;
        sine_table[9] = 8'd79;
        sine_table[10] = 8'd37;
        sine_table[11] = 8'd10;
        sine_table[12] = 8'd0;
        sine_table[13] = 8'd10;
        sine_table[14] = 8'd37;
        sine_table[15] = 8'd79;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr <= 8'd0;
        else
            addr <= addr_next;
    end
    
    always @(posedge clk)
        sine_out <= sine_table[addr[7:4]];
endmodule