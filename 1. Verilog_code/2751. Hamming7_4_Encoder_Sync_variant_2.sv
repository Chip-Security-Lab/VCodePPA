//SystemVerilog
module Hamming7_4_Encoder_Sync (
    input clk,            // 系统时钟
    input rst_n,          // 异步低复位
    input [3:0] data_in,  // 4位输入数据
    output reg [6:0] code_out // 7位编码输出
);
    always @(posedge clk or negedge rst_n) begin
        code_out <= (!rst_n) ? 7'b0 : {
            data_in[3:1],
            data_in[3] ^ data_in[2] ^ data_in[0],
            data_in[3] ^ data_in[1] ^ data_in[0],
            data_in[2] ^ data_in[1] ^ data_in[0],
            data_in[0]
        };
    end
endmodule