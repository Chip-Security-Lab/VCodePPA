//SystemVerilog
module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    // 查找表实现加法结果 (val + 5)
    reg [3:0] add_lut [0:15];
    // 查找表实现减法结果 (val - 3)
    reg [3:0] sub_lut [0:15];
    
    // 初始化查找表
    initial begin
        // 加法查找表 (val + 5)
        add_lut[0] = 4'd5;   // 0 + 5 = 5
        add_lut[1] = 4'd6;   // 1 + 5 = 6
        add_lut[2] = 4'd7;   // 2 + 5 = 7
        add_lut[3] = 4'd8;   // 3 + 5 = 8
        add_lut[4] = 4'd9;   // 4 + 5 = 9
        add_lut[5] = 4'd10;  // 5 + 5 = 10
        add_lut[6] = 4'd11;  // 6 + 5 = 11
        add_lut[7] = 4'd12;  // 7 + 5 = 12
        add_lut[8] = 4'd13;  // 8 + 5 = 13
        add_lut[9] = 4'd14;  // 9 + 5 = 14
        add_lut[10] = 4'd15; // 10 + 5 = 15
        add_lut[11] = 4'd0;  // 11 + 5 = 16 (溢出为0)
        add_lut[12] = 4'd1;  // 12 + 5 = 17 (溢出为1)
        add_lut[13] = 4'd2;  // 13 + 5 = 18 (溢出为2)
        add_lut[14] = 4'd3;  // 14 + 5 = 19 (溢出为3)
        add_lut[15] = 4'd4;  // 15 + 5 = 20 (溢出为4)
        
        // 减法查找表 (val - 3)
        sub_lut[0] = 4'd13;  // 0 - 3 = -3 (补码表示为13)
        sub_lut[1] = 4'd14;  // 1 - 3 = -2 (补码表示为14)
        sub_lut[2] = 4'd15;  // 2 - 3 = -1 (补码表示为15)
        sub_lut[3] = 4'd0;   // 3 - 3 = 0
        sub_lut[4] = 4'd1;   // 4 - 3 = 1
        sub_lut[5] = 4'd2;   // 5 - 3 = 2
        sub_lut[6] = 4'd3;   // 6 - 3 = 3
        sub_lut[7] = 4'd4;   // 7 - 3 = 4
        sub_lut[8] = 4'd5;   // 8 - 3 = 5
        sub_lut[9] = 4'd6;   // 9 - 3 = 6
        sub_lut[10] = 4'd7;  // 10 - 3 = 7
        sub_lut[11] = 4'd8;  // 11 - 3 = 8
        sub_lut[12] = 4'd9;  // 12 - 3 = 9
        sub_lut[13] = 4'd10; // 13 - 3 = 10
        sub_lut[14] = 4'd11; // 14 - 3 = 11
        sub_lut[15] = 4'd12; // 15 - 3 = 12
    end
    
    // 使用查找表获取计算结果
    wire [3:0] add_result = add_lut[val];
    wire [3:0] sub_result = sub_lut[val];
    
    // 选择输出
    assign mux_out = sel ? add_result : sub_result;
    
    // 反转操作也可以用查找表实现，但是简单的取反操作已经很高效
    assign invert = ~val;
endmodule