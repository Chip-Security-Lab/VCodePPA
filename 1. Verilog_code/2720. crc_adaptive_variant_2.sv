//SystemVerilog
module crc_adaptive #(parameter MAX_WIDTH=64)(
    input clk,
    input [MAX_WIDTH-1:0] data,
    input [5:0] width_sel,  // 输入有效位宽
    output reg [31:0] crc
);
    reg [31:0] crc_next;
    
    // 将组合逻辑和时序逻辑分开处理，改善逻辑结构
    integer i;
    always @(*) begin
        crc_next = crc;
        for (i = 0; i < width_sel; i = i + 1) begin
            // 使用if-else结构替代条件运算符
            if (crc_next[31] ^ data[i]) begin
                crc_next = (crc_next << 1) ^ 32'h04C11DB7;
            end else begin
                crc_next = crc_next << 1;
            end
        end
    end
    
    // 时序逻辑
    always @(posedge clk) begin
        crc <= crc_next;
    end
endmodule