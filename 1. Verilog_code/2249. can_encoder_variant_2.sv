//SystemVerilog
module can_encoder (
    input clk, tx_req,
    input [10:0] id,
    input [7:0] data,
    output reg tx,
    output tx_ack
);
    reg [14:0] crc;
    reg [3:0] state, next_state;
    reg [3:0] bit_counter, next_bit_counter;
    reg next_tx;
    reg [14:0] next_crc;
    
    // 组合逻辑部分 - 计算下一状态
    always @(*) begin
        next_state = state;
        next_bit_counter = bit_counter;
        next_tx = tx;
        next_crc = crc;
        
        case(state)
            4'd0: if(tx_req) begin
                next_tx = 1'b0; // Start bit
                next_crc = 15'h7FF;
                next_state = 4'd1;
                next_bit_counter = 4'd0;
            end
            4'd1: begin // ID transmission
                next_tx = id[10 - bit_counter];
                next_crc = (crc << 1) ^ ((crc[14] ^ next_tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd10) 
                    next_state = 4'd2;
                else
                    next_bit_counter = bit_counter + 4'd1;
            end
            4'd2: begin // RTR bit
                next_tx = 1'b0; // 数据帧
                next_crc = (crc << 1) ^ ((crc[14] ^ next_tx) ? 15'h4599 : 15'h0000);
                next_state = 4'd3;
                next_bit_counter = 4'd0;
            end
            4'd3: begin // 数据长度
                next_tx = (bit_counter < 4) ? 1'b0 : 1'b1; // 8字节数据
                next_crc = (crc << 1) ^ ((crc[14] ^ next_tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd3)
                    next_state = 4'd4;
                else
                    next_bit_counter = bit_counter + 4'd1;
            end
            4'd4: begin // 发送数据
                next_tx = data[7 - bit_counter];
                next_crc = (crc << 1) ^ ((crc[14] ^ next_tx) ? 15'h4599 : 15'h0000);
                
                if(bit_counter == 4'd7)
                    next_state = 4'd5;
                else
                    next_bit_counter = bit_counter + 4'd1;
            end
            4'd5: begin // 发送CRC
                next_tx = crc[14 - bit_counter];
                
                if(bit_counter == 4'd14)
                    next_state = 4'd0;
                else
                    next_bit_counter = bit_counter + 4'd1;
            end
            default: next_state = 4'd0;
        endcase
    end
    
    // 时序逻辑部分 - 更新状态
    always @(posedge clk) begin
        state <= next_state;
        bit_counter <= next_bit_counter;
        tx <= next_tx;
        crc <= next_crc;
    end
    
    assign tx_ack = (state == 4'd0);
endmodule