//SystemVerilog
module Pipeline_XNOR(
    input wire clk,
    input wire [15:0] a, b,
    output wire [15:0] out
);
    reg [15:0] a_reg, b_reg;
    reg [15:0] result;
    
    // 合并两个具有相同时钟触发条件的always块
    always @(posedge clk) begin
        // 第一级流水线寄存器
        a_reg <= a;
        b_reg <= b;
        
        // 第二级流水线 - XNOR运算
        result <= ~(a_reg ^ b_reg);
    end
    
    // 输出赋值
    assign out = result;
    
endmodule