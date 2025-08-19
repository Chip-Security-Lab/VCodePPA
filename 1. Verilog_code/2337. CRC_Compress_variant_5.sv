//SystemVerilog
module CRC_Compress #(parameter POLY=32'h04C11DB7) (
    input wire clk, 
    input wire en,
    input wire [31:0] data,
    output reg [31:0] crc
);
    wire feedback = crc[31] ^ data[31];
    
    always @(posedge clk) begin
        if(en) begin
            // 使用条件赋值替代乘法表达式，减少逻辑深度
            crc <= {crc[30:0], 1'b0} ^ (feedback ? POLY : 32'h0);
            // 优化：直接使用位拼接处理左移操作，避免额外的逻辑门
        end
    end
endmodule