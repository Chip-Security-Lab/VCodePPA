//SystemVerilog
module or_gate_2input_32bit (
    input wire clk,
    input wire rst_n,
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] y
);
    // 中间结果寄存器
    reg [15:0] lower_result;
    reg [15:0] upper_result;
    
    always @(posedge clk or negedge rst_n) begin
        // 使用条件运算符替代if-else结构
        lower_result <= (!rst_n) ? 16'b0 : (a[15:0] | b[15:0]);
        upper_result <= (!rst_n) ? 16'b0 : (a[31:16] | b[31:16]);
        y <= (!rst_n) ? 32'b0 : {upper_result, lower_result};
    end
endmodule