//SystemVerilog
module crc_config_xor #(
    parameter WIDTH = 16,
    parameter INIT = 16'hFFFF,
    parameter FINAL_XOR = 16'h0000
)(
    input clk, en, 
    input [WIDTH-1:0] data,
    output [WIDTH-1:0] crc_result,
    output reg [WIDTH-1:0] crc
);
    // 组合逻辑部分 - CRC计算的下一个状态
    wire [WIDTH-1:0] crc_next;
    wire [WIDTH-1:0] poly_mask;
    
    // 根据CRC最高位选择多项式掩码
    assign poly_mask = crc[WIDTH-1] ? 16'h1021 : 0;
    
    // 计算下一个CRC值 - 组合逻辑
    assign crc_next = (crc << 1) ^ (data ^ poly_mask);
    
    // 最终XOR输出 - 组合逻辑
    assign crc_result = crc ^ FINAL_XOR;
    
    // 时序逻辑部分 - 寄存器更新
    always @(posedge clk) begin
        if (!en) begin
            crc <= INIT;
        end else begin
            crc <= crc_next;
        end
    end
endmodule