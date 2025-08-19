//SystemVerilog
module speed_optimized_crc32(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire data_valid,
    output reg [31:0] crc
);
    parameter [31:0] POLY = 32'h04C11DB7;
    
    // Buffer registers for high fanout signals
    reg [31:0] data_buf;
    reg [31:0] poly_buf;
    reg [31:0] h0_buf;
    
    // Pipeline stage 1 - Buffer high fanout signals
    always @(posedge clk) begin
        if (rst) begin
            data_buf <= 32'h0;
            poly_buf <= 32'h0;
            h0_buf <= 32'h0;
        end else begin
            data_buf <= data;
            poly_buf <= POLY;
            h0_buf <= crc;
        end
    end
    
    // Pipeline stage 2 - CRC calculation with buffered signals
    wire [31:0] bit0_xor = (h0_buf[31] ^ data_buf[0]) ? poly_buf : 32'h0;
    wire [31:0] bit0_crc = {h0_buf[30:0], 1'b0} ^ bit0_xor;
    
    wire [31:0] bit1_xor = (bit0_crc[31] ^ data_buf[1]) ? poly_buf : 32'h0;
    wire [31:0] bit1_crc = {bit0_crc[30:0], 1'b0} ^ bit1_xor;
    
    wire [31:0] bit2_xor = (bit1_crc[31] ^ data_buf[2]) ? poly_buf : 32'h0;
    wire [31:0] bit2_crc = {bit1_crc[30:0], 1'b0} ^ bit2_xor;
    
    wire [31:0] bit3_xor = (bit2_crc[31] ^ data_buf[3]) ? poly_buf : 32'h0;
    wire [31:0] bit3_crc = {bit2_crc[30:0], 1'b0} ^ bit3_xor;
    
    wire [31:0] byte0_result = bit3_crc;
    wire last_bit = byte0_result[31] ^ data_buf[31];
    wire [31:0] full_result = {byte0_result[30:0], last_bit};
    
    // Pipeline stage 3 - Final CRC register
    always @(posedge clk) begin
        if (rst)
            crc <= 32'hFFFFFFFF;
        else if (data_valid)
            crc <= full_result;
    end
endmodule