//SystemVerilog
module modbus_decoder #(parameter TIMEOUT=1000000) (
    input clk, rx,
    output reg [7:0] data,
    output reg valid,
    output reg crc_err
);
    reg [31:0] timer;
    reg [15:0] crc;
    reg [3:0] bitcnt;
    reg rx_prev;
    
    // 预计算CRC表常量
    localparam CRC_POLY = 16'hA001;
    
    // 优化的CRC16计算函数 - 展开循环并平衡路径
    function [15:0] crc16_update;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] result;
        reg [7:0] i;
    begin
        // 预先计算异或
        result = crc_in ^ {8'h00, data};
        
        // 优化的4步计算 (8步拆分为2x4步，减少关键路径)
        // 前4位处理
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        
        // 后4位处理
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? CRC_POLY : 16'h0000);
        
        crc16_update = result;
    end
    endfunction
    
    // 计算CRC的中间结果
    wire [15:0] next_crc = crc16_update(data ^ crc[7:0], crc);
    
    // 检测RX边沿
    wire rx_negedge = rx_prev & ~rx;
    
    always @(posedge clk) begin
        // 存储前一个rx值用于边沿检测
        rx_prev <= rx;
        
        // 优化定时器逻辑 - 简化条件路径
        if (rx)
            timer <= 32'h0;
        else if (timer < TIMEOUT)
            timer <= timer + 32'h1;
            
        // 优化位计数器和CRC逻辑 - 减少case语句复杂度
        if (bitcnt < 4'h8) begin
            // 接收数据位
            data <= {data[6:0], rx};
            bitcnt <= bitcnt + 4'h1;
            crc <= next_crc;
        end
        else if (bitcnt == 4'h8) begin
            // 完成一个字节接收
            crc_err <= (crc != 16'h0000);
            valid <= (crc == 16'h0000);
            bitcnt <= 4'h0;
        end
        else begin
            // 重置位计数器
            bitcnt <= 4'h0;
        end
    end
endmodule