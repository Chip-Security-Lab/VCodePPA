//SystemVerilog
module gray_lut #(parameter DEPTH=256, AW=8)(
    input clk, en,
    input [AW-1:0] addr,
    input [7:0] subtrahend,
    input sub_en,
    output reg [7:0] gray_out
);
    reg [7:0] lut [0:DEPTH-1];
    
    // 缓冲高扇出信号
    reg [7:0] subtrahend_buf1, subtrahend_buf2;
    reg [7:0] minuend, minuend_buf1, minuend_buf2;
    
    // 读取查找表初始化数据
    initial $readmemh("gray_table.hex", lut);
    
    // 地址解码逻辑
    wire [7:0] lut_data = lut[addr];
    
    // 缓冲寄存器
    always @(posedge clk) begin
        minuend <= lut_data;
        minuend_buf1 <= minuend;
        minuend_buf2 <= minuend;
        
        subtrahend_buf1 <= subtrahend;
        subtrahend_buf2 <= subtrahend;
    end
    
    // 并行前缀减法器实现
    // 基础传播和生成信号
    wire p_init = 1'b0;
    wire g_init = 1'b1;  // 减法中借位初始为1
    
    // 第一阶段计算传播和生成信号
    wire [7:0] p_stage1;
    wire [7:0] g_stage1;
    
    // 为高扇出信号p和g添加缓冲结构
    reg [3:0] p_buf1, p_buf2;
    reg [3:0] g_buf1, g_buf2;
    
    // 分组扇出缓冲 - 生成传播和生成信号
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_pg_low
            assign p_stage1[i] = minuend_buf1[i] | ~subtrahend_buf1[i];
            assign g_stage1[i] = minuend_buf1[i] & ~subtrahend_buf1[i];
        end
        
        for (i = 4; i < 8; i = i + 1) begin : gen_pg_high
            assign p_stage1[i] = minuend_buf2[i] | ~subtrahend_buf2[i];
            assign g_stage1[i] = minuend_buf2[i] & ~subtrahend_buf2[i];
        end
    endgenerate
    
    // 添加p和g信号的缓冲寄存器
    always @(posedge clk) begin
        p_buf1 <= p_stage1[3:0];
        p_buf2 <= p_stage1[7:4];
        g_buf1 <= g_stage1[3:0];
        g_buf2 <= g_stage1[7:4];
    end
    
    // 前缀计算缓冲区
    reg [8:0] p_lvl1_reg, g_lvl1_reg;
    reg [8:0] p_lvl2_reg, g_lvl2_reg;
    
    // 第一级前缀计算
    wire [8:0] p_lvl1, g_lvl1;
    
    // 添加i信号的缓冲寄存器
    reg [3:0] i_buf1, i_buf2;
    
    // 预先计算的信号组
    always @(posedge clk) begin
        i_buf1 <= {2'b0, 2'b0};  // 代替genvar的缓存
        i_buf2 <= {4'd6, 4'd4};  // 缓存常用的索引值
    end
    
    assign p_lvl1[0] = p_init;
    assign g_lvl1[0] = g_init;
    
    generate
        for (i = 0; i < 4; i = i + 2) begin : prefix_lvl1_low
            if (i > 0) begin
                assign p_lvl1[i] = p_buf1[i-1] & p_lvl1[i-1];
                assign g_lvl1[i] = g_buf1[i-1] | (p_buf1[i-1] & g_lvl1[i-1]);
            end
            
            if (i+1 < 4) begin
                assign p_lvl1[i+1] = p_buf1[i];
                assign g_lvl1[i+1] = g_buf1[i];
            end
        end
    
        for (i = 4; i < 9; i = i + 2) begin : prefix_lvl1_high
            if (i > 4) begin
                assign p_lvl1[i] = p_buf2[i-5] & p_lvl1[i-1];
                assign g_lvl1[i] = g_buf2[i-5] | (p_buf2[i-5] & g_lvl1[i-1]);
            end else begin
                assign p_lvl1[i] = p_buf2[i-4] & p_lvl1[i-1];
                assign g_lvl1[i] = g_buf2[i-4] | (p_buf2[i-4] & g_lvl1[i-1]);
            end
            
            if (i+1 < 9) begin
                assign p_lvl1[i+1] = p_buf2[i-4];
                assign g_lvl1[i+1] = g_buf2[i-4];
            end
        end
    endgenerate
    
    // 缓冲寄存第一级结果
    always @(posedge clk) begin
        p_lvl1_reg <= p_lvl1;
        g_lvl1_reg <= g_lvl1;
    end
    
    // 第二级前缀计算
    wire [8:0] p_lvl2, g_lvl2;
    
    assign p_lvl2[0] = p_lvl1_reg[0];
    assign g_lvl2[0] = g_lvl1_reg[0];
    
    generate
        for (i = 1; i < 5; i = i + 4) begin : prefix_lvl2_low
            assign p_lvl2[i] = p_lvl1_reg[i];
            assign g_lvl2[i] = g_lvl1_reg[i];
            
            assign p_lvl2[i+1] = p_lvl1_reg[i+1];
            assign g_lvl2[i+1] = g_lvl1_reg[i+1];
            
            assign p_lvl2[i+2] = p_lvl1_reg[i+2] & p_lvl1_reg[i];
            assign g_lvl2[i+2] = g_lvl1_reg[i+2] | (p_lvl1_reg[i+2] & g_lvl1_reg[i]);
            
            assign p_lvl2[i+3] = p_lvl1_reg[i+3];
            assign g_lvl2[i+3] = g_lvl1_reg[i+3];
        end
    
        for (i = 5; i < 9; i = i + 4) begin : prefix_lvl2_high
            assign p_lvl2[i] = p_lvl1_reg[i] & p_lvl1_reg[i-4];
            assign g_lvl2[i] = g_lvl1_reg[i] | (p_lvl1_reg[i] & g_lvl1_reg[i-4]);
            
            if (i+1 < 9) begin
                assign p_lvl2[i+1] = p_lvl1_reg[i+1];
                assign g_lvl2[i+1] = g_lvl1_reg[i+1];
            end
            
            if (i+2 < 9) begin
                assign p_lvl2[i+2] = p_lvl1_reg[i+2] & p_lvl1_reg[i-2];
                assign g_lvl2[i+2] = g_lvl1_reg[i+2] | (p_lvl1_reg[i+2] & g_lvl1_reg[i-2]);
            end
            
            if (i+3 < 9) begin
                assign p_lvl2[i+3] = p_lvl1_reg[i+3];
                assign g_lvl2[i+3] = g_lvl1_reg[i+3];
            end
        end
    endgenerate
    
    // 缓冲寄存第二级结果
    always @(posedge clk) begin
        p_lvl2_reg <= p_lvl2;
        g_lvl2_reg <= g_lvl2;
    end
    
    // 第三级前缀计算 - 最终进位计算
    wire [8:0] p_lvl3, g_lvl3;
    
    assign p_lvl3[0] = p_lvl2_reg[0];
    assign g_lvl3[0] = g_lvl2_reg[0];
    
    // 使用索引缓冲减少扇出
    assign p_lvl3[1] = p_lvl2_reg[1];
    assign g_lvl3[1] = g_lvl2_reg[1];
    
    assign p_lvl3[2] = p_lvl2_reg[2];
    assign g_lvl3[2] = g_lvl2_reg[2];
    
    assign p_lvl3[3] = p_lvl2_reg[3];
    assign g_lvl3[3] = g_lvl2_reg[3];
    
    assign p_lvl3[4] = p_lvl2_reg[4] & p_lvl2_reg[0];
    assign g_lvl3[4] = g_lvl2_reg[4] | (p_lvl2_reg[4] & g_lvl2_reg[0]);
    
    assign p_lvl3[5] = p_lvl2_reg[5];
    assign g_lvl3[5] = g_lvl2_reg[5];
    
    assign p_lvl3[6] = p_lvl2_reg[6] & p_lvl2_reg[0];
    assign g_lvl3[6] = g_lvl2_reg[6] | (p_lvl2_reg[6] & g_lvl2_reg[0]);
    
    assign p_lvl3[7] = p_lvl2_reg[7];
    assign g_lvl3[7] = g_lvl2_reg[7];
    
    assign p_lvl3[8] = p_lvl2_reg[8] & p_lvl2_reg[4];
    assign g_lvl3[8] = g_lvl2_reg[8] | (p_lvl2_reg[8] & g_lvl2_reg[4]);
    
    // 计算最终进位
    wire [8:0] carry = g_lvl3;
    
    // 缓冲进位信号
    reg [7:0] carry_buf;
    always @(posedge clk) begin
        carry_buf <= carry[7:0];
    end
    
    // 计算差值
    wire [7:0] diff;
    
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_diff_low
            assign diff[i] = minuend_buf1[i] ^ subtrahend_buf1[i] ^ carry_buf[i];
        end
        
        for (i = 4; i < 8; i = i + 1) begin : gen_diff_high
            assign diff[i] = minuend_buf2[i] ^ subtrahend_buf2[i] ^ carry_buf[i];
        end
    endgenerate
    
    // 根据操作模式选择输出
    always @(posedge clk) begin
        if (en && sub_en)
            gray_out <= diff;  // 使用减法器结果
        else if (en)
            gray_out <= lut[addr];  // 使用查找表结果
    end
endmodule