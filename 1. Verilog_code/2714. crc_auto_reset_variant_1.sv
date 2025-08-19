//SystemVerilog
module crc_auto_reset #(parameter MAX_COUNT=255)(
    input clk, start,
    input [7:0] data_stream,
    output reg [15:0] crc,
    output done
);
    reg [8:0] counter;
    
    // 实现crc_next函数
    function [15:0] crc_next;
        input [15:0] crc_in;
        input [7:0] data;
        begin
            // 简化的CRC计算
            crc_next = {crc_in[14:0], 1'b0} ^ 
                    (crc_in[15] ? 16'h8005 : 16'h0000) ^ 
                    {8'h00, data};
        end
    endfunction

    // 使用独热编码表示状态
    localparam INIT_STATE = 2'b01;
    localparam CALC_STATE = 2'b10;
    
    reg [1:0] state;
    
    always @(posedge clk) begin
        case ({start, state})
            {1'b1, INIT_STATE}, 
            {1'b1, CALC_STATE}: begin
                // start信号触发重置
                counter <= 0;
                crc <= 16'hFFFF;
                state <= CALC_STATE;
            end
            
            {1'b0, CALC_STATE}: begin
                if (counter < MAX_COUNT) begin
                    // 计算CRC
                    crc <= crc_next(crc, data_stream);
                    counter <= counter + 1;
                end
            end
            
            default: begin
                // 保持状态
                state <= INIT_STATE;
            end
        endcase
    end

    assign done = (counter == MAX_COUNT);
endmodule