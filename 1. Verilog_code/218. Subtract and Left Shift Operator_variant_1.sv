//SystemVerilog
module subtract_shift_left (
    input wire clk,                    // 时钟信号
    input wire rst_n,                  // 低电平有效复位
    input wire [7:0] a,                // 输入数据a
    input wire [7:0] b,                // 输入数据b  
    input wire [2:0] shift_amount,     // 移位量
    output reg [7:0] difference,       // 差值输出
    output reg [7:0] shifted_result    // 移位结果输出
);

    // 寄存器输入值
    reg [7:0] a_reg, b_reg;
    reg [2:0] shift_amount_reg;
    
    // 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
            shift_amount_reg <= 3'd0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            shift_amount_reg <= shift_amount;
        end
    end
    
    // 组合逻辑计算移动到寄存的输入之后
    wire [7:0] sub_result = a_reg - b_reg;
    wire [7:0] shift_result = a_reg << shift_amount_reg;
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference <= 8'd0;
            shifted_result <= 8'd0;
        end else begin
            difference <= sub_result;
            shifted_result <= shift_result;
        end
    end

endmodule