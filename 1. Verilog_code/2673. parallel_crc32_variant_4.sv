//SystemVerilog
module parallel_crc32_pipelined(
    input wire clock,
    input wire clear,
    input wire [31:0] data_word,
    input wire word_valid,
    output wire [31:0] crc_value,
    output wire result_valid
);
    localparam POLY = 32'h04C11DB7;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 流水线数据寄存器
    reg [31:0] data_stage1;
    reg [31:0] crc_current;
    reg [31:0] crc_stage1, crc_stage2, crc_stage3;
    
    // 关键路径切割 - 第一级流水线预计算寄存器
    reg [7:0] byte0_poly_terms [0:7];
    
    // 关键路径切割 - 第二级流水线预计算寄存器
    reg [7:0] byte1_poly_terms [0:7];
    
    // 关键路径切割 - 第三级流水线预计算寄存器
    reg [7:0] byte2_poly_terms [0:7];
    
    // 关键路径切割 - 第四级流水线预计算寄存器
    reg [7:0] byte3_poly_terms [0:7];
    
    // 第一级流水线的多项式预计算
    wire [7:0] byte0_term0 = {8{data_stage1[31]}} & POLY[31:24];
    wire [7:0] byte0_term1 = {8{data_stage1[30]}} & POLY[30:23];
    wire [7:0] byte0_term2 = {8{data_stage1[29]}} & POLY[29:22];
    wire [7:0] byte0_term3 = {8{data_stage1[28]}} & POLY[28:21];
    wire [7:0] byte0_term4 = {8{data_stage1[27]}} & POLY[27:20];
    wire [7:0] byte0_term5 = {8{data_stage1[26]}} & POLY[26:19];
    wire [7:0] byte0_term6 = {8{data_stage1[25]}} & POLY[25:18];
    wire [7:0] byte0_term7 = {8{data_stage1[24]}} & POLY[24:17];
    
    // 第二级流水线的多项式预计算
    wire [7:0] byte1_term0 = {8{data_stage1[23]}} & POLY[31:24];
    wire [7:0] byte1_term1 = {8{data_stage1[22]}} & POLY[30:23];
    wire [7:0] byte1_term2 = {8{data_stage1[21]}} & POLY[29:22];
    wire [7:0] byte1_term3 = {8{data_stage1[20]}} & POLY[28:21];
    wire [7:0] byte1_term4 = {8{data_stage1[19]}} & POLY[27:20];
    wire [7:0] byte1_term5 = {8{data_stage1[18]}} & POLY[26:19];
    wire [7:0] byte1_term6 = {8{data_stage1[17]}} & POLY[25:18];
    wire [7:0] byte1_term7 = {8{data_stage1[16]}} & POLY[24:17];
    
    // 第三级流水线的多项式预计算
    wire [7:0] byte2_term0 = {8{data_stage1[15]}} & POLY[31:24];
    wire [7:0] byte2_term1 = {8{data_stage1[14]}} & POLY[30:23];
    wire [7:0] byte2_term2 = {8{data_stage1[13]}} & POLY[29:22];
    wire [7:0] byte2_term3 = {8{data_stage1[12]}} & POLY[28:21];
    wire [7:0] byte2_term4 = {8{data_stage1[11]}} & POLY[27:20];
    wire [7:0] byte2_term5 = {8{data_stage1[10]}} & POLY[26:19];
    wire [7:0] byte2_term6 = {8{data_stage1[9]}} & POLY[25:18];
    wire [7:0] byte2_term7 = {8{data_stage1[8]}} & POLY[24:17];
    
    // 第四级流水线的多项式预计算
    wire [7:0] byte3_term0 = {8{data_stage1[7]}} & POLY[31:24];
    wire [7:0] byte3_term1 = {8{data_stage1[6]}} & POLY[30:23];
    wire [7:0] byte3_term2 = {8{data_stage1[5]}} & POLY[29:22];
    wire [7:0] byte3_term3 = {8{data_stage1[4]}} & POLY[28:21];
    wire [7:0] byte3_term4 = {8{data_stage1[3]}} & POLY[27:20];
    wire [7:0] byte3_term5 = {8{data_stage1[2]}} & POLY[26:19];
    wire [7:0] byte3_term6 = {8{data_stage1[1]}} & POLY[25:18];
    wire [7:0] byte3_term7 = {8{data_stage1[0]}} & POLY[24:17];
    
    // 使用分段组合逻辑进行计算，减少关键路径
    wire [31:0] byte0_result = (crc_current << 8) ^ 
                             {byte0_poly_terms[0] ^ byte0_poly_terms[1] ^ 
                              byte0_poly_terms[2] ^ byte0_poly_terms[3],
                              byte0_poly_terms[4] ^ byte0_poly_terms[5] ^ 
                              byte0_poly_terms[6] ^ byte0_poly_terms[7],
                              24'b0};
    
    wire [31:0] byte1_result = (crc_stage1 << 8) ^ 
                             {byte1_poly_terms[0] ^ byte1_poly_terms[1] ^ 
                              byte1_poly_terms[2] ^ byte1_poly_terms[3],
                              byte1_poly_terms[4] ^ byte1_poly_terms[5] ^ 
                              byte1_poly_terms[6] ^ byte1_poly_terms[7],
                              24'b0};
    
    wire [31:0] byte2_result = (crc_stage2 << 8) ^ 
                             {byte2_poly_terms[0] ^ byte2_poly_terms[1] ^ 
                              byte2_poly_terms[2] ^ byte2_poly_terms[3],
                              byte2_poly_terms[4] ^ byte2_poly_terms[5] ^ 
                              byte2_poly_terms[6] ^ byte2_poly_terms[7],
                              24'b0};
    
    wire [31:0] byte3_result = (crc_stage3 << 8) ^ 
                             {byte3_poly_terms[0] ^ byte3_poly_terms[1] ^ 
                              byte3_poly_terms[2] ^ byte3_poly_terms[3],
                              byte3_poly_terms[4] ^ byte3_poly_terms[5] ^ 
                              byte3_poly_terms[6] ^ byte3_poly_terms[7],
                              24'b0};
    
    reg [31:0] crc_result;
    
    // 输出赋值
    assign crc_value = crc_result;
    assign result_valid = valid_stage4;
    
    always @(posedge clock) begin
        if (clear) begin
            // 复位所有流水线寄存器和有效信号
            crc_current <= 32'hFFFFFFFF;
            crc_result <= 32'hFFFFFFFF;
            crc_stage1 <= 32'hFFFFFFFF;
            crc_stage2 <= 32'hFFFFFFFF;
            crc_stage3 <= 32'hFFFFFFFF;
            data_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            
            // 清零所有预计算项寄存器
            for (int i = 0; i < 8; i++) begin
                byte0_poly_terms[i] <= 8'b0;
                byte1_poly_terms[i] <= 8'b0;
                byte2_poly_terms[i] <= 8'b0;
                byte3_poly_terms[i] <= 8'b0;
            end
        end
        else begin
            // 第一级流水线 - 输入寄存和多项式项预计算
            if (word_valid) begin
                data_stage1 <= data_word;
                valid_stage1 <= 1'b1;
                
                // 预计算多项式项并存入寄存器，切割关键路径
                byte0_poly_terms[0] <= byte0_term0;
                byte0_poly_terms[1] <= byte0_term1;
                byte0_poly_terms[2] <= byte0_term2;
                byte0_poly_terms[3] <= byte0_term3;
                byte0_poly_terms[4] <= byte0_term4;
                byte0_poly_terms[5] <= byte0_term5;
                byte0_poly_terms[6] <= byte0_term6;
                byte0_poly_terms[7] <= byte0_term7;
                
                byte1_poly_terms[0] <= byte1_term0;
                byte1_poly_terms[1] <= byte1_term1;
                byte1_poly_terms[2] <= byte1_term2;
                byte1_poly_terms[3] <= byte1_term3;
                byte1_poly_terms[4] <= byte1_term4;
                byte1_poly_terms[5] <= byte1_term5;
                byte1_poly_terms[6] <= byte1_term6;
                byte1_poly_terms[7] <= byte1_term7;
                
                byte2_poly_terms[0] <= byte2_term0;
                byte2_poly_terms[1] <= byte2_term1;
                byte2_poly_terms[2] <= byte2_term2;
                byte2_poly_terms[3] <= byte2_term3;
                byte2_poly_terms[4] <= byte2_term4;
                byte2_poly_terms[5] <= byte2_term5;
                byte2_poly_terms[6] <= byte2_term6;
                byte2_poly_terms[7] <= byte2_term7;
                
                byte3_poly_terms[0] <= byte3_term0;
                byte3_poly_terms[1] <= byte3_term1;
                byte3_poly_terms[2] <= byte3_term2;
                byte3_poly_terms[3] <= byte3_term3;
                byte3_poly_terms[4] <= byte3_term4;
                byte3_poly_terms[5] <= byte3_term5;
                byte3_poly_terms[6] <= byte3_term6;
                byte3_poly_terms[7] <= byte3_term7;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
            
            // 第二级流水线 - 第一字节处理
            crc_stage1 <= valid_stage1 ? byte0_result : crc_stage1;
            valid_stage2 <= valid_stage1;
            
            // 第三级流水线 - 第二字节处理
            crc_stage2 <= valid_stage2 ? byte1_result : crc_stage2;
            valid_stage3 <= valid_stage2;
            
            // 第四级流水线 - 第三字节处理
            crc_stage3 <= valid_stage3 ? byte2_result : crc_stage3;
            valid_stage4 <= valid_stage3;
            
            // 输出结果
            if (valid_stage4) begin
                crc_result <= byte3_result;
            end
            
            // 更新当前CRC值用于下一个输入
            if (valid_stage4) begin
                crc_current <= byte3_result;
            end
            else if (word_valid && !valid_stage1 && !valid_stage2 && !valid_stage3) begin
                // 当流水线为空且有新输入时，使用当前值
                crc_current <= crc_result;
            end
        end
    end
endmodule