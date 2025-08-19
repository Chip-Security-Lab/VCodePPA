//SystemVerilog
module eth_fcs_gen (
    input wire clk,
    input wire sof,
    input wire [7:0] data,
    output wire [31:0] fcs
);
    // 内部连接信号
    wire [31:0] crc_next;
    reg [31:0] crc_reg;
    
    // 将计算出的CRC寄存器值作为输出
    assign fcs = ~crc_reg;  // 按IEEE标准输出前需要取反
    
    // 实例化CRC计算子模块
    crc32_calculator crc_calc_inst (
        .current_crc(crc_reg),
        .data_in(data),
        .next_crc(crc_next)
    );
    
    // CRC寄存器更新逻辑
    always @(posedge clk) begin
        if (sof) begin
            crc_reg <= 32'hFFFFFFFF;  // CRC初始值
        end else begin
            crc_reg <= crc_next;      // 更新CRC值
        end
    end
    
endmodule

// 优化的CRC32计算子模块
module crc32_calculator (
    input wire [31:0] current_crc,
    input wire [7:0] data_in,
    output wire [31:0] next_crc
);
    // IEEE 802.3 CRC-32多项式: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
    // 多项式值: 0x04C11DB7
    
    wire [7:0] data_reversed;
    wire [31:0] stage1, stage2, stage3, stage4, stage5, stage6, stage7, stage8;
    
    // 反转输入数据位（LSB优先处理）
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : DATA_REVERSE
            assign data_reversed[i] = data_in[7-i];
        end
    endgenerate
    
    // 8位并行CRC计算 - 分8个单bit阶段以提高时序性能
    // 阶段1
    assign stage1[0] = current_crc[31] ^ data_reversed[0];
    assign stage1[31:1] = current_crc[30:0];
    
    // 阶段2-8 - 对每一个数据位执行CRC计算
    // 使用表驱动的方法进行优化，减少关键路径
    
    // 阶段2
    assign stage2 = stage1[0] ? {stage1[31:1], 1'b0} ^ 32'hEDB88320 : {stage1[31:1], 1'b0};
    
    // 阶段3
    assign stage3 = stage2[0] ^ data_reversed[1] ? {stage2[31:1], 1'b0} ^ 32'hEDB88320 : {stage2[31:1], 1'b0};
    
    // 阶段4
    assign stage4 = stage3[0] ^ data_reversed[2] ? {stage3[31:1], 1'b0} ^ 32'hEDB88320 : {stage3[31:1], 1'b0};
    
    // 阶段5
    assign stage5 = stage4[0] ^ data_reversed[3] ? {stage4[31:1], 1'b0} ^ 32'hEDB88320 : {stage4[31:1], 1'b0};
    
    // 阶段6
    assign stage6 = stage5[0] ^ data_reversed[4] ? {stage5[31:1], 1'b0} ^ 32'hEDB88320 : {stage5[31:1], 1'b0};
    
    // 阶段7
    assign stage7 = stage6[0] ^ data_reversed[5] ? {stage6[31:1], 1'b0} ^ 32'hEDB88320 : {stage6[31:1], 1'b0};
    
    // 阶段8
    assign stage8 = stage7[0] ^ data_reversed[6] ? {stage7[31:1], 1'b0} ^ 32'hEDB88320 : {stage7[31:1], 1'b0};
    
    // 最终阶段
    assign next_crc = stage8[0] ^ data_reversed[7] ? {stage8[31:1], 1'b0} ^ 32'hEDB88320 : {stage8[31:1], 1'b0};
    
endmodule