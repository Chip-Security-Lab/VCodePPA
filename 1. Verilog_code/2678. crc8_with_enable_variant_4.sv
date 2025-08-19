//SystemVerilog
module crc8_with_handshake(
    input wire clk,
    input wire rst_n,
    input wire valid,       // 数据有效信号（原enable改为valid）
    input wire [7:0] data,  // 输入数据
    output wire ready,      // 准备好接收信号（新增）
    output reg [7:0] crc,   // CRC结果
    output reg crc_valid    // CRC结果有效信号（新增）
);
    parameter POLY = 8'h07;
    
    // 内部状态和信号
    reg busy;               // 指示模块当前是否处于计算状态
    assign ready = !busy;   // 当模块不忙时，可以接收新数据
    
    // 使用表达式级联计算所有位的CRC
    wire [7:0] bit0_crc = {crc[6:0], 1'b0} ^ ((crc[7] ^ data[0]) ? POLY : 8'h00);
    wire [7:0] bit1_crc = {bit0_crc[6:0], 1'b0} ^ ((bit0_crc[7] ^ data[1]) ? POLY : 8'h00);
    wire [7:0] bit2_crc = {bit1_crc[6:0], 1'b0} ^ ((bit1_crc[7] ^ data[2]) ? POLY : 8'h00);
    wire [7:0] bit3_crc = {bit2_crc[6:0], 1'b0} ^ ((bit2_crc[7] ^ data[3]) ? POLY : 8'h00);
    wire [7:0] bit4_crc = {bit3_crc[6:0], 1'b0} ^ ((bit3_crc[7] ^ data[4]) ? POLY : 8'h00);
    wire [7:0] bit5_crc = {bit4_crc[6:0], 1'b0} ^ ((bit4_crc[7] ^ data[5]) ? POLY : 8'h00);
    wire [7:0] bit6_crc = {bit5_crc[6:0], 1'b0} ^ ((bit5_crc[7] ^ data[6]) ? POLY : 8'h00);
    wire [7:0] bit7_crc = {bit6_crc[6:0], 1'b0} ^ ((bit6_crc[7] ^ data[7]) ? POLY : 8'h00);
    
    // 状态和输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 8'h00;
            busy <= 1'b0;
            crc_valid <= 1'b0;
        end else begin
            if (valid && ready) begin  // 握手成功，接收新数据
                crc <= bit7_crc;
                busy <= 1'b1;
                crc_valid <= 1'b1;  // 数据已处理，结果有效
            end else if (busy) begin
                busy <= 1'b0;  // 处理完成，释放忙状态
            end else begin
                crc_valid <= 1'b0;  // 没有新数据处理时，结果无效
            end
        end
    end
endmodule