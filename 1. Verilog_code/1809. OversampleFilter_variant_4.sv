//SystemVerilog
module OversampleFilter #(parameter OVERSAMPLE=3) (
    input clk, 
    input din,
    output reg dout
);
    reg [OVERSAMPLE-1:0] sample_buf;
    reg [3:0] count;
    
    // 合并所有 posedge clk 触发的 always 块
    always @(posedge clk) begin
        // 移位寄存器采样
        sample_buf <= {sample_buf[OVERSAMPLE-2:0], din};
        
        // 计数逻辑 - 使用位计数以提高效率
        count <= $countones(sample_buf[OVERSAMPLE-2:0] & {(OVERSAMPLE-1){1'b1}}) + din;
        
        // 多数表决输出
        dout <= (count >= (OVERSAMPLE/2));
    end
endmodule