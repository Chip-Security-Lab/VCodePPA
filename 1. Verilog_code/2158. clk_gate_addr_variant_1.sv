//SystemVerilog
module clk_gate_addr #(parameter AW=2) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [2**AW-1:0] decode
);
    // 优化流水线结构
    reg en_q1, en_q2;
    reg [AW-1:0] addr_q1, addr_q2;
    reg [2**AW-1:0] decode_pre;
    
    // 合并流水线寄存器，减少时钟路径
    always @(posedge clk) begin
        // 第一级流水线
        en_q1 <= en;
        addr_q1 <= addr;
        
        // 第二级流水线
        en_q2 <= en_q1;
        addr_q2 <= addr_q1;
        
        // 第三级流水线 - 优化的解码操作
        decode_pre <= en_q2 ? ({{(2**AW-1){1'b0}}, 1'b1} << addr_q2) : {2**AW{1'b0}};
        
        // 最终输出寄存
        decode <= decode_pre;
    end
endmodule