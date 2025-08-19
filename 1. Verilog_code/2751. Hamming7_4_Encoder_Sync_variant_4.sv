//SystemVerilog
module Hamming7_4_Encoder_Sync (
    input clk,            // 系统时钟
    input rst_n,          // 异步低复位
    input [3:0] data_in,  // 4位输入数据
    output reg [6:0] code_out // 7位编码输出
);

// 定义计算奇偶校验位的中间信号
reg [2:0] parity_bits;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        code_out <= 7'b0;
        parity_bits <= 3'b0;
    end
    else begin
        // 预计算所有奇偶校验位，减少关键路径延迟
        parity_bits[0] <= data_in[3] ^ data_in[2] ^ data_in[0];
        parity_bits[1] <= data_in[3] ^ data_in[1] ^ data_in[0];
        parity_bits[2] <= data_in[2] ^ data_in[1] ^ data_in[0];
        
        // 并行分配输出位
        code_out <= {data_in[3:1], parity_bits, data_in[0]};
    end
end
endmodule