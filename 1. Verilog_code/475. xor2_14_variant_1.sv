//SystemVerilog
//===================================================================
// Top level module - 2输入XOR门的层次化实现
//===================================================================
module xor2_14 (
    input  wire clk,    // 添加时钟信号以实现正确的寄存功能
    input  wire rst_n,  // 添加复位信号以提高可靠性
    input  wire A, B,   // 输入信号
    output wire Y       // 输出信号
);
    // 内部连线
    wire xor_result;
    
    // 实例化XOR逻辑计算子模块
    xor_logic_unit xor_logic_inst (
        .in_a(A),
        .in_b(B),
        .xor_result(xor_result)
    );
    
    // 实例化输出寄存器子模块，添加时钟和复位
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(xor_result),
        .data_out(Y)
    );
    
endmodule

//===================================================================
// XOR Logic Unit - 执行XOR逻辑运算
//===================================================================
module xor_logic_unit #(
    parameter DELAY = 1  // 参数化延迟，便于时序调整
)(
    input  wire in_a, in_b,
    output wire xor_result
);
    // 使用中间变量实现XOR，提高清晰度
    wire and1_out = in_a & ~in_b;
    wire and2_out = ~in_a & in_b;
    
    // 基于基本逻辑门实现XOR，可能在某些ASIC库中优化的更好
    assign #DELAY xor_result = and1_out | and2_out;

endmodule

//===================================================================
// Output Register - 带时钟和复位的输出寄存器
//===================================================================
module output_register (
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 低电平有效的异步复位
    input  wire data_in,   // 数据输入
    output reg  data_out   // 寄存后的数据输出
);
    // 同步寄存器带异步复位，提高电路可靠性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;  // 复位值
        end else begin
            data_out <= data_in;
        end
    end
endmodule