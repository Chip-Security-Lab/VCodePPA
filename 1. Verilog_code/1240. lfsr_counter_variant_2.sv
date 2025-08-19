//SystemVerilog
// 顶层模块
module lfsr_counter (
    input  wire clk,
    input  wire rst,
    output wire [7:0] lfsr
);
    // 直接生成反馈信号，无需额外模块
    wire feedback = lfsr[7] ^ (lfsr[5] ^ lfsr[4] ^ lfsr[3]);
    
    // 状态寄存器
    reg [7:0] lfsr_reg;
    
    // 更新LFSR状态
    always @(posedge clk) begin
        if (rst)
            lfsr_reg <= 8'h01;  // 非零种子值
        else
            lfsr_reg <= {lfsr_reg[6:0], feedback};
    end
    
    // 输出连线
    assign lfsr = lfsr_reg;
    
endmodule