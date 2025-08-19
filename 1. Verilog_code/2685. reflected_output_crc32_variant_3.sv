//SystemVerilog
module reflected_output_crc32(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire [31:0] crc_out
);
    // 寄存器声明
    reg [31:0] crc_reg;
    
    // 组合逻辑信号声明
    wire [31:0] crc_next;
    wire [31:0] reflected_crc;
    
    // 组合逻辑模块实例化
    crc_combinational crc_comb_inst(
        .crc_reg(crc_reg),
        .data_in(data),
        .reflected_crc(reflected_crc),
        .crc_next(crc_next)
    );
    
    // 输出赋值
    assign crc_out = reflected_crc ^ 32'hFFFFFFFF;
    
    // 时序逻辑块
    always @(posedge clk) begin
        if (rst) 
            crc_reg <= 32'hFFFFFFFF;
        else if (valid) 
            crc_reg <= crc_next;
    end
endmodule

// 组合逻辑模块
module crc_combinational(
    input wire [31:0] crc_reg,
    input wire [7:0] data_in,
    output wire [31:0] reflected_crc,
    output wire [31:0] crc_next
);
    wire [31:0] shift_input;
    wire [31:0] polynomial;
    
    // 常量与数据准备
    assign polynomial = 32'h04C11DB7;
    assign shift_input = {crc_reg[30:0], 1'b0};
    
    // 反射CRC输出位
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: bit_reflect
            assign reflected_crc[i] = crc_reg[31-i];
        end
    endgenerate
    
    // 使用优化的并行Kogge-Stone加法器进行CRC计算
    parallel_crc_adder pcrc_inst(
        .shift_input(shift_input),
        .polynomial(polynomial),
        .crc_bit_31(crc_reg[31]),
        .data_bit_0(data_in[0]),
        .crc_next(crc_next)
    );
endmodule

// 优化的并行CRC加法器
module parallel_crc_adder(
    input wire [31:0] shift_input,
    input wire [31:0] polynomial,
    input wire crc_bit_31,
    input wire data_bit_0,
    output wire [31:0] crc_next
);
    wire poly_select;
    wire [31:0] poly_mask;
    
    // 多路复用器替代条件，减少关键路径
    assign poly_select = crc_bit_31 ^ data_bit_0;
    assign poly_mask = {32{poly_select}} & polynomial;
    
    // 使用优化的Kogge-Stone加法器
    optimized_kogge_stone_adder ksa_inst(
        .a(shift_input),
        .b(poly_mask),
        .sum(crc_next)
    );
endmodule

// 优化的Kogge-Stone 32-bit加法器
module optimized_kogge_stone_adder(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);
    // 预先计算的生成和传播信号
    wire [31:0] g0, p0;
    wire [31:0] g1, p1;
    wire [31:0] g2, p2;
    wire [31:0] g3, p3;
    wire [31:0] g4, p4;
    wire [31:0] g5, p5;
    
    // 初始生成和传播信号
    assign g0 = a & b;
    assign p0 = a ^ b;
    
    // 级联逻辑 - 复用生成块减少数据路径
    genvar i;
    generate
        // 第1级: 1位距离
        for (i = 0; i < 32; i = i + 1) begin: stage1
            if(i == 0) begin
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end
            else begin
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end
        end
        
        // 第2级: 2位距离
        for (i = 0; i < 32; i = i + 1) begin: stage2
            if(i < 2) begin
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
            else begin
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end
        end
        
        // 第3级: 4位距离
        for (i = 0; i < 32; i = i + 1) begin: stage3
            if(i < 4) begin
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
            else begin
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end
        end
        
        // 第4级: 8位距离
        for (i = 0; i < 32; i = i + 1) begin: stage4
            if(i < 8) begin
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end
            else begin
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end
        end
        
        // 第5级: 16位距离
        for (i = 0; i < 32; i = i + 1) begin: stage5
            if(i < 16) begin
                assign g5[i] = g4[i];
                assign p5[i] = p4[i];
            end
            else begin
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
                assign p5[i] = p4[i] & p4[i-16];
            end
        end
    endgenerate
    
    // 计算最终和
    assign sum[0] = p0[0];
    generate
        for (i = 1; i < 32; i = i + 1) begin: sum_calc
            assign sum[i] = p0[i] ^ g5[i-1];
        end
    endgenerate
endmodule