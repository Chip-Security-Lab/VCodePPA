//SystemVerilog
module speed_optimized_crc32(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire req,          // 将data_valid改为req
    output reg ack,          // 新增ack信号作为输出
    output reg [31:0] crc
);
    parameter [31:0] POLY = 32'h04C11DB7;
    
    // 内部状态控制
    reg busy;
    
    // 优化位运算表达式，移除条件操作符，直接使用布尔运算
    wire crc_data_xor0 = crc[31] ^ data[0];
    wire [31:0] mask0 = {32{crc_data_xor0}} & POLY;
    wire [31:0] bit0_crc = {crc[30:0], 1'b0} ^ mask0;
    
    wire crc_data_xor1 = bit0_crc[31] ^ data[1];
    wire [31:0] mask1 = {32{crc_data_xor1}} & POLY;
    wire [31:0] bit1_crc = {bit0_crc[30:0], 1'b0} ^ mask1;
    
    wire crc_data_xor2 = bit1_crc[31] ^ data[2];
    wire [31:0] mask2 = {32{crc_data_xor2}} & POLY;
    wire [31:0] bit2_crc = {bit1_crc[30:0], 1'b0} ^ mask2;
    
    wire crc_data_xor3 = bit2_crc[31] ^ data[3];
    wire [31:0] mask3 = {32{crc_data_xor3}} & POLY;
    wire [31:0] bit3_crc = {bit2_crc[30:0], 1'b0} ^ mask3;
    
    // 按字节进行处理
    wire [31:0] byte0_result = bit3_crc;
    
    // 优化最终结果计算
    wire [31:0] full_result = {byte0_result[30:0], byte0_result[31] ^ data[31]};
    
    // Req-Ack握手逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 1'b0;
            ack <= 1'b0;
            crc <= 32'hFFFFFFFF;
        end else begin
            if (req && !busy) begin
                // 收到新请求且当前不忙
                busy <= 1'b1;
                ack <= 1'b1;
                crc <= full_result;
            end else if (busy && ack) begin
                // 正在处理且已发出确认
                ack <= 1'b0;
                busy <= 1'b0;
            end
        end
    end
endmodule