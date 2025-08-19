module can_encoder (
    input clk, tx_req,
    input [10:0] id,
    input [7:0] data,
    output reg tx,
    output tx_ack
);
    reg [14:0] crc;
    reg [3:0] state;
    reg [3:0] bit_counter;
    
    always @(posedge clk) begin
        case(state)
            4'd0: if(tx_req) begin
                tx <= 1'b0; // Start bit
                crc <= 15'h7FF;
                state <= 4'd1;
                bit_counter <= 4'd0;
            end
            4'd1: begin // ID transmission
                tx <= id[10 - bit_counter];
                crc <= (crc << 1) ^ ((crc[14] ^ tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd10) 
                    state <= 4'd2;
                else
                    bit_counter <= bit_counter + 4'd1;
            end
            4'd2: begin // RTR bit
                tx <= 1'b0; // 数据帧
                crc <= (crc << 1) ^ ((crc[14] ^ tx) ? 15'h4599 : 15'h0000);
                state <= 4'd3;
                bit_counter <= 4'd0;
            end
            4'd3: begin // 数据长度
                tx <= (bit_counter < 4) ? 1'b0 : 1'b1; // 8字节数据
                crc <= (crc << 1) ^ ((crc[14] ^ tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd3)
                    state <= 4'd4;
                else
                    bit_counter <= bit_counter + 4'd1;
            end
            4'd4: begin // 发送数据
                tx <= data[7 - bit_counter];
                crc <= (crc << 1) ^ ((crc[14] ^ tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd7)
                    state <= 4'd5;
                else
                    bit_counter <= bit_counter + 4'd1;
            end
            4'd5: begin // 发送CRC
                tx <= crc[14 - bit_counter];
                
                if(bit_counter == 4'd14)
                    state <= 4'd0;
                else
                    bit_counter <= bit_counter + 4'd1;
            end
            default: state <= 4'd0;
        endcase
    end
    
    assign tx_ack = (state == 4'd0);
endmodule