//SystemVerilog
module pl_reg_bitslice #(parameter W=8) (
    input clk, en,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
    // 内部寄存器和线网
    reg [W-1:0] data_out_reg;
    reg [W-1:0] subtrahend_reg;
    wire [W-1:0] complement_result;
    wire [W-1:0] subtraction_result;
    
    // 输出赋值
    assign data_out = data_out_reg;
    
    // 对减数取反
    assign complement_result = ~subtrahend_reg;
    
    // 使用补码加法实现减法 (A-B = A+(-B) = A+(~B+1))
    assign subtraction_result = data_in + complement_result + 1'b1;
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (en) begin
            subtrahend_reg <= data_in;      // 存储当前输入值作为下一周期的减数
            data_out_reg <= subtraction_result;  // 存储减法结果到输出寄存器
        end
    end
endmodule