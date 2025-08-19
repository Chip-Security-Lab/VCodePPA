//SystemVerilog
module twos_complement (
    input signed [3:0] value,
    output [3:0] absolute,
    output [3:0] negative
);
    // 存储查找表中的预计算值
    reg [3:0] abs_lut [0:15];
    reg [3:0] neg_lut [0:15];
    
    // 使用查找表映射
    assign absolute = abs_lut[value];
    assign negative = neg_lut[value];
    
    // 查找表初始化
    initial begin
        // 计算绝对值查找表 - 展开的正数部分
        abs_lut[0] = 0;
        abs_lut[1] = 1;
        abs_lut[2] = 2;
        abs_lut[3] = 3;
        abs_lut[4] = 4;
        abs_lut[5] = 5;
        abs_lut[6] = 6;
        abs_lut[7] = 7;
        
        // 计算绝对值查找表 - 展开的负数部分
        abs_lut[8] = -8;
        abs_lut[9] = -9;
        abs_lut[10] = -10;
        abs_lut[11] = -11;
        abs_lut[12] = -12;
        abs_lut[13] = -13;
        abs_lut[14] = -14;
        abs_lut[15] = -15;
        
        // 计算负值查找表 - 完全展开
        neg_lut[0] = -0;
        neg_lut[1] = -1;
        neg_lut[2] = -2;
        neg_lut[3] = -3;
        neg_lut[4] = -4;
        neg_lut[5] = -5;
        neg_lut[6] = -6;
        neg_lut[7] = -7;
        neg_lut[8] = -8;
        neg_lut[9] = -9;
        neg_lut[10] = -10;
        neg_lut[11] = -11;
        neg_lut[12] = -12;
        neg_lut[13] = -13;
        neg_lut[14] = -14;
        neg_lut[15] = -15;
    end
endmodule