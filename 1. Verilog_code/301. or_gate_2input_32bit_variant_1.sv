//SystemVerilog
module or_gate_2input_32bit (
    input wire clk,           // Clock for pipelined operation
    input wire rst_n,         // Reset signal for pipeline registers
    input wire [31:0] a,      // Input operand A
    input wire [31:0] b,      // Input operand B
    output reg [31:0] y       // Output result (registered)
);
    // 将输入直接进行或运算，消除输入寄存器延迟
    wire [15:0] lower_or = a[15:0] | b[15:0];    // 直接进行低16位或运算
    wire [15:0] upper_or = a[31:16] | b[31:16];  // 直接进行高16位或运算
    
    // 中间结果寄存器 - 直接寄存或运算的结果
    reg [15:0] lower_result, upper_result;
    
    // 第一级流水线 - 寄存或运算的结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_result <= 16'b0;
            upper_result <= 16'b0;
        end else begin
            lower_result <= lower_or;
            upper_result <= upper_or;
        end
    end
    
    // 第二级流水线 - 组合结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 32'b0;
        end else begin
            y <= {upper_result, lower_result};
        end
    end
endmodule