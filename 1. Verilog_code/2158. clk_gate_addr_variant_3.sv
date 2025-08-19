//SystemVerilog
module clk_gate_addr #(parameter AW=2) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [2**AW-1:0] decode
);
    // 减少缓冲级数，优化信号传播
    reg en_buf;
    reg [AW-1:0] addr_buf;
    
    // 单一缓冲级别，减少寄存器数量
    always @(posedge clk) begin
        en_buf <= en;
        addr_buf <= addr;
    end
    
    // 使用单一解码逻辑，简化控制路径
    // 通过独热码编码直接生成解码结果
    always @(posedge clk) begin
        if (en_buf) begin
            // 使用移位操作替代case语句，提高效率
            decode <= (1'b1 << addr_buf);
        end else begin
            decode <= {2**AW{1'b0}};
        end
    end
endmodule