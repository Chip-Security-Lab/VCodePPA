//SystemVerilog
module speed_optimized_crc32(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire data_req,     // 由 data_valid 转换而来
    output reg data_ack,     // 对应原来的 ready 信号
    output reg [31:0] crc
);
    parameter [31:0] POLY = 32'h04C11DB7;
    
    reg [31:0] bit0_crc;
    reg [31:0] bit1_crc;
    reg [31:0] bit2_crc;
    reg [31:0] bit3_crc;
    reg [31:0] byte0_result;
    reg [31:0] full_result;
    reg req_received;       // 用于跟踪请求状态
    
    always @(*) begin
        // bit0 calculation
        if (crc[31] ^ data[0]) begin
            bit0_crc = {crc[30:0], 1'b0} ^ POLY;
        end else begin
            bit0_crc = {crc[30:0], 1'b0};
        end
        
        // bit1 calculation
        if (bit0_crc[31] ^ data[1]) begin
            bit1_crc = {bit0_crc[30:0], 1'b0} ^ POLY;
        end else begin
            bit1_crc = {bit0_crc[30:0], 1'b0};
        end
        
        // bit2 calculation
        if (bit1_crc[31] ^ data[2]) begin
            bit2_crc = {bit1_crc[30:0], 1'b0} ^ POLY;
        end else begin
            bit2_crc = {bit1_crc[30:0], 1'b0};
        end
        
        // bit3 calculation
        if (bit2_crc[31] ^ data[3]) begin
            bit3_crc = {bit2_crc[30:0], 1'b0} ^ POLY;
        end else begin
            bit3_crc = {bit2_crc[30:0], 1'b0};
        end
        
        // Process first byte
        byte0_result = bit3_crc;
        
        // Final calculation (simplified version)
        full_result = {byte0_result[30:0], byte0_result[31] ^ data[31]};
    end
    
    always @(posedge clk) begin
        if (rst) begin
            crc <= 32'hFFFFFFFF;
            data_ack <= 1'b0;
            req_received <= 1'b0;
        end else begin
            // 请求-应答握手逻辑
            if (data_req && !req_received) begin
                // 新的请求到达
                crc <= full_result;
                data_ack <= 1'b1;        // 产生应答信号
                req_received <= 1'b1;     // 标记请求已接收
            end else if (!data_req && req_received) begin
                // 请求已撤销，复位状态
                data_ack <= 1'b0;
                req_received <= 1'b0;
            end else if (data_req && req_received) begin
                // 保持应答状态直到请求撤销
                data_ack <= 1'b1;
            end else begin
                // data_req == 0 且 req_received == 0
                data_ack <= 1'b0;
            end
        end
    end
endmodule