//SystemVerilog
module shift_parity_checker (
    input wire clk,
    input wire serial_in,
    output reg parity
);
    // 将数据流分为两个阶段：数据捕获和奇偶校验计算
    reg [7:0] shift_reg;
    reg [7:0] parity_data_reg;
    
    // Stage 1: 数据捕获 - 将输入数据移入移位寄存器
    always @(posedge clk) begin
        shift_reg <= {shift_reg[6:0], serial_in};
    end
    
    // Stage 2: 奇偶校验计算 - 将移位寄存器中的数据进行奇偶校验
    always @(posedge clk) begin
        // 将数据寄存起来以减少逻辑深度
        parity_data_reg <= shift_reg;
        // 计算奇偶校验位
        parity <= ^parity_data_reg;
    end
endmodule