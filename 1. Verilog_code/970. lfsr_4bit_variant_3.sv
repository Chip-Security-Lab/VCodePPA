//SystemVerilog
module lfsr_4bit (
    input wire clk,
    input wire rst_n,
    output wire [3:0] pseudo_random
);
    reg [3:0] lfsr_q;
    wire feedback;
    
    // 优化反馈路径以减少逻辑级数
    assign feedback = lfsr_q[1] ^ lfsr_q[3];
    
    // 使用非阻塞赋值并改进复位逻辑的实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_q <= 4'b0001;  // 明确的复位值
        else
            lfsr_q <= {lfsr_q[2:0], feedback};  // 移位寄存器更新
    end
    
    // 将内部寄存器直接连接到输出
    assign pseudo_random = lfsr_q;
    
endmodule