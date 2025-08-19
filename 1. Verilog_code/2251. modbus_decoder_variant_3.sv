//SystemVerilog
//IEEE 1364-2005 Verilog标准
module modbus_decoder #(parameter TIMEOUT=1000000) (
    input wire clk, rx,
    output reg [7:0] data,
    output reg valid,
    output reg crc_err
);
    reg [31:0] timer;
    reg [15:0] crc;
    reg [3:0] bitcnt;
    
    // 优化的Modbus CRC16表实现
    function [15:0] crc16_update;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] result;
        integer i;
    begin
        result = crc_in ^ {8'h00, data};
        
        for (i = 0; i < 8; i = i + 1) begin
            if (result[0])
                result = (result >> 1) ^ 16'hA001;
            else
                result = result >> 1;
        end
        
        crc16_update = result;
    end
    endfunction
    
    // 重置信号 - 使用参数化的比较
    wire timeout_reached = (timer >= TIMEOUT - 1);
    
    // 优化位计数比较 - 使用等式和范围检查替代多个比较
    wire byte_complete = (bitcnt == 4'd7);
    wire byte_receiving = (bitcnt < 4'd8);
    wire process_crc = (bitcnt == 4'd8);
    
    always @(posedge clk) begin
        // 优化计时器逻辑 - 使用条件优先级
        if (rx)
            timer <= 32'h0;
        else if (timer < TIMEOUT - 1)  // 使用范围检查避免比较器链
            timer <= timer + 32'h1;
            
        // 优化位计数和数据处理逻辑
        if (timeout_reached) begin
            bitcnt <= 4'h0;
        end
        else if (byte_receiving) begin
            if (!rx) begin  // 仅在RX为低时处理数据
                // 优化位移操作，减少资源使用
                data <= {rx, data[7:1]};
                bitcnt <= bitcnt + 4'h1;
                
                // 优化条件检查 - 将CRC更新移到外部条件
                if (byte_complete)
                    crc <= crc16_update(data, crc);
            end
        end
        else if (process_crc) begin
            // 优化比较逻辑 - 使用单一逻辑表达式
            valid <= (crc == 16'h0000);
            crc_err <= (crc != 16'h0000);
            bitcnt <= 4'h0;
        end
    end
endmodule