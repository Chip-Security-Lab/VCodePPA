//SystemVerilog
module multi_standard_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [1:0] crc_type, // 00: CRC8, 01: CRC16, 10: CRC32
    output reg [31:0] crc_out
);
    // 常量定义
    localparam [7:0] POLY8 = 8'hD5;
    localparam [15:0] POLY16 = 16'h1021;
    localparam [31:0] POLY32 = 32'h04C11DB7;
    
    // 预计算的多项式选择
    reg [31:0] poly_selected;
    reg feedback_bit;
    
    // CRC 计算的中间结果
    reg [31:0] next_crc;
    
    always @(*) begin
        // 反馈位计算 - 从数据位与CRC的MSB进行XOR
        feedback_bit = data[0] ^ crc_out[crc_type == 2'b00 ? 7 : 
                                          crc_type == 2'b01 ? 15 : 31];
        
        // 预选择多项式，避免在主逻辑中进行case语句
        case (crc_type)
            2'b00: poly_selected = {24'h0, POLY8};
            2'b01: poly_selected = {16'h0, POLY16};
            2'b10: poly_selected = POLY32;
            default: poly_selected = 32'h0;
        endcase
        
        // 计算下一个CRC值
        case (crc_type)
            2'b00: next_crc = {24'h0, {crc_out[6:0], 1'b0} ^ (feedback_bit ? POLY8 : 8'h0)};
            2'b01: next_crc = {16'h0, {crc_out[14:0], 1'b0} ^ (feedback_bit ? POLY16 : 16'h0)};
            2'b10: next_crc = {crc_out[30:0], 1'b0} ^ (feedback_bit ? POLY32 : 32'h0);
            default: next_crc = crc_out;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 32'h0;
        end else begin
            crc_out <= next_crc;
        end
    end
endmodule