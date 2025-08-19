//SystemVerilog
module speed_optimized_crc32(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire data_valid,
    output reg [31:0] crc
);
    parameter [31:0] POLY = 32'h04C11DB7;
    
    reg [31:0] bit0_crc;
    reg [31:0] bit1_crc;
    reg [31:0] bit2_crc;
    reg [31:0] bit3_crc;
    reg [31:0] byte0_result;
    reg [31:0] full_result;
    
    // Bit 0 calculation
    always @(*) begin
        case(crc[31] ^ data[0])
            1'b1: bit0_crc = {crc[30:0], 1'b0} ^ POLY;
            1'b0: bit0_crc = {crc[30:0], 1'b0};
        endcase
    end
    
    // Bit 1 calculation
    always @(*) begin
        case(bit0_crc[31] ^ data[1])
            1'b1: bit1_crc = {bit0_crc[30:0], 1'b0} ^ POLY;
            1'b0: bit1_crc = {bit0_crc[30:0], 1'b0};
        endcase
    end
    
    // Bit 2 calculation
    always @(*) begin
        case(bit1_crc[31] ^ data[2])
            1'b1: bit2_crc = {bit1_crc[30:0], 1'b0} ^ POLY;
            1'b0: bit2_crc = {bit1_crc[30:0], 1'b0};
        endcase
    end
    
    // Bit 3 calculation
    always @(*) begin
        case(bit2_crc[31] ^ data[3])
            1'b1: bit3_crc = {bit2_crc[30:0], 1'b0} ^ POLY;
            1'b0: bit3_crc = {bit2_crc[30:0], 1'b0};
        endcase
    end
    
    // Byte 0 result assignment
    always @(*) begin
        byte0_result = bit3_crc;
    end
    
    // Full result calculation
    always @(*) begin
        full_result = {byte0_result[30:0], byte0_result[31] ^ data[31]};
    end
    
    // CRC register update
    always @(posedge clk) begin
        if (rst) begin
            crc <= 32'hFFFFFFFF;
        end else if (data_valid) begin
            crc <= full_result;
        end
    end

endmodule