//SystemVerilog
module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output reg [7:0] dout
);
    // 桶形移位器的中间信号
    wire [7:0] shift1_result;
    wire [7:0] shift2_result;
    wire [7:0] shift4_result;
    wire [7:0] shift_result;
    
    // 第一级移位 (移位1位) - 使用显式多路复用器结构
    wire [7:0] shift1_op0 = din;
    wire [7:0] shift1_op1 = {din[6:0], 1'b0};
    assign shift1_result = shift[0] ? shift1_op1 : shift1_op0;
    
    // 第二级移位 (移位2位) - 使用显式多路复用器结构
    wire [7:0] shift2_op0 = shift1_result;
    wire [7:0] shift2_op1 = {shift1_result[5:0], 2'b00};
    assign shift2_result = shift[1] ? shift2_op1 : shift2_op0;
    
    // 第三级移位 (移位4位) - 使用显式多路复用器结构
    wire [7:0] shift4_op0 = shift2_result;
    wire [7:0] shift4_op1 = {shift2_result[3:0], 4'b0000};
    assign shift4_result = shift[2] ? shift4_op1 : shift4_op0;
    
    // 最终移位结果
    assign shift_result = shift4_result;
    
    // 饱和逻辑 - 使用显式多路复用器结构
    wire shift_gt_5 = (shift > 3'd5);
    wire [7:0] saturated_value = 8'hFF;
    wire [7:0] normal_value = shift_result;
    
    // 使用显式多路复用器代替条件语句
    always @* begin
        case (shift_gt_5)
            1'b1: dout = saturated_value;
            1'b0: dout = normal_value;
        endcase
    end
endmodule