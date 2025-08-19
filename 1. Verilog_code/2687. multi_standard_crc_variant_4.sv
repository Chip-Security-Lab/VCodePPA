//SystemVerilog
module multi_standard_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [1:0] crc_type, // 00: CRC8, 01: CRC16, 10: CRC32
    output reg [31:0] crc_out
);
    // CRC多项式常量定义
    localparam [7:0] POLY8 = 8'hD5;
    localparam [15:0] POLY16 = 16'h1021;
    localparam [31:0] POLY32 = 32'h04C11DB7;
    
    // 各类型CRC的中间结果
    reg [7:0] crc8_next;
    reg [15:0] crc16_next;
    reg [31:0] crc32_next;
    
    // 输入位与CRC最高位的异或结果
    wire crc8_feedback = crc_out[7] ^ data[0];
    wire crc16_feedback = crc_out[15] ^ data[0];
    wire crc32_feedback = crc_out[31] ^ data[0];
    
    // CRC8计算逻辑
    always @(*) begin
        crc8_next = {crc_out[6:0], 1'b0} ^ (crc8_feedback ? POLY8 : 8'h0);
    end
    
    // CRC16计算逻辑
    always @(*) begin
        crc16_next = {crc_out[14:0], 1'b0} ^ (crc16_feedback ? POLY16 : 16'h0);
    end
    
    // CRC32计算逻辑
    always @(*) begin
        crc32_next = {crc_out[30:0], 1'b0} ^ (crc32_feedback ? POLY32 : 32'h0);
    end
    
    // CRC输出逻辑：根据crc_type选择合适的CRC结果
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 32'h0;
        end else begin
            case (crc_type)
                2'b00: crc_out[7:0] <= crc8_next;
                2'b01: crc_out[15:0] <= crc16_next;
                2'b10: crc_out <= crc32_next;
                default: crc_out <= crc_out; // 保持当前值
            endcase
        end
    end
endmodule