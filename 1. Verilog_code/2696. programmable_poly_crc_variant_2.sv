//SystemVerilog
module programmable_poly_crc(
    input wire clk,
    input wire rst,
    input wire [15:0] poly_in,
    input wire poly_valid,
    output wire poly_ready,
    input wire [7:0] data,
    input wire data_valid,
    output wire data_ready,
    output reg [15:0] crc,
    output wire crc_valid,
    input wire crc_ready
);
    reg [15:0] polynomial;
    reg processing;
    reg crc_updated;
    reg [2:0] bit_counter;
    reg [7:0] data_buffer;
    
    // 多位并行处理CRC计算，提高效率
    wire [15:0] next_crc = {crc[14:0], 1'b0} ^ 
                          ((crc[15] ^ data_buffer[bit_counter]) ? polynomial : 16'h0000);
    
    // 握手信号生成
    assign poly_ready = !processing;
    assign data_ready = !processing || (processing && bit_counter == 3'b111 && crc_ready);
    assign crc_valid = crc_updated;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            polynomial <= 16'h1021; // Default CCITT
            crc <= 16'hFFFF;
            processing <= 1'b0;
            crc_updated <= 1'b0;
            bit_counter <= 3'b000;
            data_buffer <= 8'h00;
        end else begin
            // 多态处理逻辑
            if (poly_valid && poly_ready) begin
                polynomial <= poly_in;
            end
            
            // 数据处理逻辑
            if (data_valid && data_ready && !processing) begin
                processing <= 1'b1;
                data_buffer <= data;
                bit_counter <= 3'b000;
                crc_updated <= 1'b0;
            end else if (processing) begin
                if (bit_counter == 3'b111) begin
                    if (crc_ready) begin
                        processing <= 1'b0;
                        crc_updated <= 1'b1;
                    end
                end else begin
                    bit_counter <= bit_counter + 1'b1;
                end
                
                // 按位计算CRC
                crc <= next_crc;
            end
            
            // CRC输出握手
            if (crc_valid && crc_ready) begin
                crc_updated <= 1'b0;
            end
        end
    end
endmodule