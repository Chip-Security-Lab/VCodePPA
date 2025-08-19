module modbus_decoder #(parameter TIMEOUT=1000000) (
    input clk, rx,
    output reg [7:0] data,
    output reg valid,
    output reg crc_err
);
    reg [31:0] timer;
    reg [15:0] crc;
    reg [3:0] bitcnt;
    
    // Modbus CRC16表（简化版）
    function [15:0] crc16_table;
        input [7:0] data;
        input [15:0] crc;
        reg [15:0] result;
    begin
        result = crc ^ {8'h00, data};
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        result = (result >> 1) ^ ((result[0]) ? 16'hA001 : 16'h0000);
        crc16_table = result;
    end
    endfunction
    
    always @(posedge clk) begin
        if(rx) timer <= 32'h0;
        else if(timer < TIMEOUT) timer <= timer + 32'h1;
        
        if(bitcnt < 8) begin
            data <= {data[6:0], rx};
            bitcnt <= bitcnt + 4'h1;
            crc <= crc16_table(data ^ crc[7:0], crc);
        end
        else if(bitcnt == 8) begin
            crc_err <= (crc != 16'h0000);
            valid <= (crc == 16'h0000);
            bitcnt <= 4'h0;
        end
    end
endmodule