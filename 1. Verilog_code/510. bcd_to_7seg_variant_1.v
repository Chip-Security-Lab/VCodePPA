module bcd_to_7seg(
    input [3:0] bcd,
    output reg [6:0] seg
);

    // 查找表存储7段显示码
    reg [6:0] pattern_table [0:9];
    
    // 初始化查找表
    initial begin
        pattern_table[0] = 7'b0111111;  // 0
        pattern_table[1] = 7'b0000110;  // 1
        pattern_table[2] = 7'b1011011;  // 2
        pattern_table[3] = 7'b1001111;  // 3
        pattern_table[4] = 7'b1100110;  // 4
        pattern_table[5] = 7'b1101101;  // 5
        pattern_table[6] = 7'b1111101;  // 6
        pattern_table[7] = 7'b0000111;  // 7
        pattern_table[8] = 7'b1111111;  // 8
        pattern_table[9] = 7'b1101111;  // 9
    end

    // 输入验证和索引计算
    reg [3:0] index;
    always @(*) begin
        index = (bcd < 10) ? bcd : 4'd0;
    end

    // 查找表查询和输出生成
    always @(*) begin
        if (bcd < 10) begin
            seg = pattern_table[index];
        end else begin
            seg = 7'b0000000;
        end
    end

endmodule