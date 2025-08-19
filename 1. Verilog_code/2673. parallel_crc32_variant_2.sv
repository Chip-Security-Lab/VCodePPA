//SystemVerilog
module parallel_crc32(
    input wire clock,
    input wire clear,
    input wire [31:0] data_word,
    input wire word_valid,
    output reg [31:0] crc_value
);
    localparam POLY = 32'h04C11DB7;
    
    // CRC32计算的一个简化版本，不使用过程式循环
    wire [31:0] next_crc;
    
    // 展开循环的几个关键步骤（简化版）
    wire [31:0] stage0;
    wire [31:0] stage1;
    wire [31:0] stage2;
    
    // 使用if-else代替条件运算符
    reg [31:0] crc_shifted0;
    reg [31:0] crc_xor0;
    reg [31:0] data_xor0;
    
    always @(*) begin
        crc_shifted0 = crc_value << 1;
        
        if (crc_value[31]) 
            crc_xor0 = POLY;
        else
            crc_xor0 = 0;
            
        if (data_word[31])
            data_xor0 = POLY;
        else
            data_xor0 = 0;
    end
    
    assign stage0 = crc_shifted0 ^ crc_xor0 ^ data_xor0;
    
    // 第二阶段
    reg [31:0] stage0_shifted;
    reg [31:0] stage0_xor;
    reg [31:0] data_xor1;
    
    always @(*) begin
        stage0_shifted = stage0 << 1;
        
        if (stage0[31])
            stage0_xor = POLY;
        else
            stage0_xor = 0;
            
        if (data_word[30])
            data_xor1 = POLY;
        else
            data_xor1 = 0;
    end
    
    assign stage1 = stage0_shifted ^ stage0_xor ^ data_xor1;
    
    // 第三阶段
    reg [31:0] stage1_shifted;
    reg [31:0] stage1_xor;
    reg [31:0] data_xor2;
    
    always @(*) begin
        stage1_shifted = stage1 << 1;
        
        if (stage1[31])
            stage1_xor = POLY;
        else
            stage1_xor = 0;
            
        if (data_word[29])
            data_xor2 = POLY;
        else
            data_xor2 = 0;
    end
    
    assign stage2 = stage1_shifted ^ stage1_xor ^ data_xor2;
    
    // 按字节处理
    wire [31:0] byte0_result;
    wire [31:0] byte1_result;
    wire [31:0] byte2_result;
    wire [31:0] byte3_result;
    
    // 处理第一个字节
    reg [31:0] crc_byte0_shifted;
    reg [31:0] data31_mask, data30_mask, data29_mask, data28_mask;
    reg [31:0] data27_mask, data26_mask, data25_mask, data24_mask;
    
    always @(*) begin
        crc_byte0_shifted = crc_value << 8;
        
        if (data_word[31])
            data31_mask = {8{1'b1}} & POLY;
        else
            data31_mask = 0;
            
        if (data_word[30])
            data30_mask = {8{1'b1}} & (POLY >> 1);
        else
            data30_mask = 0;
            
        if (data_word[29])
            data29_mask = {8{1'b1}} & (POLY >> 2);
        else
            data29_mask = 0;
            
        if (data_word[28])
            data28_mask = {8{1'b1}} & (POLY >> 3);
        else
            data28_mask = 0;
            
        if (data_word[27])
            data27_mask = {8{1'b1}} & (POLY >> 4);
        else
            data27_mask = 0;
            
        if (data_word[26])
            data26_mask = {8{1'b1}} & (POLY >> 5);
        else
            data26_mask = 0;
            
        if (data_word[25])
            data25_mask = {8{1'b1}} & (POLY >> 6);
        else
            data25_mask = 0;
            
        if (data_word[24])
            data24_mask = {8{1'b1}} & (POLY >> 7);
        else
            data24_mask = 0;
    end
    
    assign byte0_result = crc_byte0_shifted ^ data31_mask ^ data30_mask ^ 
                         data29_mask ^ data28_mask ^ data27_mask ^ 
                         data26_mask ^ data25_mask ^ data24_mask;
    
    // 处理第二个字节
    reg [31:0] byte0_shifted;
    reg [31:0] data23_mask, data22_mask, data21_mask, data20_mask;
    reg [31:0] data19_mask, data18_mask, data17_mask, data16_mask;
    
    always @(*) begin
        byte0_shifted = byte0_result << 8;
        
        if (data_word[23])
            data23_mask = {8{1'b1}} & POLY;
        else
            data23_mask = 0;
            
        if (data_word[22])
            data22_mask = {8{1'b1}} & (POLY >> 1);
        else
            data22_mask = 0;
            
        if (data_word[21])
            data21_mask = {8{1'b1}} & (POLY >> 2);
        else
            data21_mask = 0;
            
        if (data_word[20])
            data20_mask = {8{1'b1}} & (POLY >> 3);
        else
            data20_mask = 0;
            
        if (data_word[19])
            data19_mask = {8{1'b1}} & (POLY >> 4);
        else
            data19_mask = 0;
            
        if (data_word[18])
            data18_mask = {8{1'b1}} & (POLY >> 5);
        else
            data18_mask = 0;
            
        if (data_word[17])
            data17_mask = {8{1'b1}} & (POLY >> 6);
        else
            data17_mask = 0;
            
        if (data_word[16])
            data16_mask = {8{1'b1}} & (POLY >> 7);
        else
            data16_mask = 0;
    end
    
    assign byte1_result = byte0_shifted ^ data23_mask ^ data22_mask ^ 
                         data21_mask ^ data20_mask ^ data19_mask ^ 
                         data18_mask ^ data17_mask ^ data16_mask;
    
    // 处理第三个字节
    reg [31:0] byte1_shifted;
    reg [31:0] data15_mask, data14_mask, data13_mask, data12_mask;
    reg [31:0] data11_mask, data10_mask, data9_mask, data8_mask;
    
    always @(*) begin
        byte1_shifted = byte1_result << 8;
        
        if (data_word[15])
            data15_mask = {8{1'b1}} & POLY;
        else
            data15_mask = 0;
            
        if (data_word[14])
            data14_mask = {8{1'b1}} & (POLY >> 1);
        else
            data14_mask = 0;
            
        if (data_word[13])
            data13_mask = {8{1'b1}} & (POLY >> 2);
        else
            data13_mask = 0;
            
        if (data_word[12])
            data12_mask = {8{1'b1}} & (POLY >> 3);
        else
            data12_mask = 0;
            
        if (data_word[11])
            data11_mask = {8{1'b1}} & (POLY >> 4);
        else
            data11_mask = 0;
            
        if (data_word[10])
            data10_mask = {8{1'b1}} & (POLY >> 5);
        else
            data10_mask = 0;
            
        if (data_word[9])
            data9_mask = {8{1'b1}} & (POLY >> 6);
        else
            data9_mask = 0;
            
        if (data_word[8])
            data8_mask = {8{1'b1}} & (POLY >> 7);
        else
            data8_mask = 0;
    end
    
    assign byte2_result = byte1_shifted ^ data15_mask ^ data14_mask ^ 
                         data13_mask ^ data12_mask ^ data11_mask ^ 
                         data10_mask ^ data9_mask ^ data8_mask;
    
    // 处理第四个字节
    reg [31:0] byte2_shifted;
    reg [31:0] data7_mask, data6_mask, data5_mask, data4_mask;
    reg [31:0] data3_mask, data2_mask, data1_mask, data0_mask;
    
    always @(*) begin
        byte2_shifted = byte2_result << 8;
        
        if (data_word[7])
            data7_mask = {8{1'b1}} & POLY;
        else
            data7_mask = 0;
            
        if (data_word[6])
            data6_mask = {8{1'b1}} & (POLY >> 1);
        else
            data6_mask = 0;
            
        if (data_word[5])
            data5_mask = {8{1'b1}} & (POLY >> 2);
        else
            data5_mask = 0;
            
        if (data_word[4])
            data4_mask = {8{1'b1}} & (POLY >> 3);
        else
            data4_mask = 0;
            
        if (data_word[3])
            data3_mask = {8{1'b1}} & (POLY >> 4);
        else
            data3_mask = 0;
            
        if (data_word[2])
            data2_mask = {8{1'b1}} & (POLY >> 5);
        else
            data2_mask = 0;
            
        if (data_word[1])
            data1_mask = {8{1'b1}} & (POLY >> 6);
        else
            data1_mask = 0;
            
        if (data_word[0])
            data0_mask = {8{1'b1}} & (POLY >> 7);
        else
            data0_mask = 0;
    end
    
    assign byte3_result = byte2_shifted ^ data7_mask ^ data6_mask ^ 
                         data5_mask ^ data4_mask ^ data3_mask ^ 
                         data2_mask ^ data1_mask ^ data0_mask;
    
    assign next_crc = byte3_result;
    
    always @(posedge clock) begin
        if (clear)
            crc_value <= 32'hFFFFFFFF;
        else if (word_valid)
            crc_value <= next_crc;
    end
endmodule