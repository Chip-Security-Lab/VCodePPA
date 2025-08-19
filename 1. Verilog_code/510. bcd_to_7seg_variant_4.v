module bcd_to_7seg(
    input wire clk,          // 时钟输入
    input wire rst_n,        // 异步复位，低电平有效
    input wire [3:0] bcd_in, // BCD码输入
    output reg [6:0] seg_out // 七段数码管输出
);

    // 输入寄存器级
    reg [3:0] bcd_reg;
    
    // 查找表实现
    wire [6:0] seg_lut [0:15];
    
    // 查找表初始化
    assign seg_lut[0]  = 7'b0111111;  // 0
    assign seg_lut[1]  = 7'b0000110;  // 1
    assign seg_lut[2]  = 7'b1011011;  // 2
    assign seg_lut[3]  = 7'b1001111;  // 3
    assign seg_lut[4]  = 7'b1100110;  // 4
    assign seg_lut[5]  = 7'b1101101;  // 5
    assign seg_lut[6]  = 7'b1111101;  // 6
    assign seg_lut[7]  = 7'b0000111;  // 7
    assign seg_lut[8]  = 7'b1111111;  // 8
    assign seg_lut[9]  = 7'b1101111;  // 9
    assign seg_lut[10] = 7'b0000000;  // 10
    assign seg_lut[11] = 7'b0000000;  // 11
    assign seg_lut[12] = 7'b0000000;  // 12
    assign seg_lut[13] = 7'b0000000;  // 13
    assign seg_lut[14] = 7'b0000000;  // 14
    assign seg_lut[15] = 7'b0000000;  // 15

    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_reg <= 4'b0;
        end else begin
            bcd_reg <= bcd_in;
        end
    end

    // 查找表输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_out <= 7'b0;
        end else begin
            seg_out <= seg_lut[bcd_reg];
        end
    end

endmodule