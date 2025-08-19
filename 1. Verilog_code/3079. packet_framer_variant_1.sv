//SystemVerilog
module packet_framer(
    input wire clk, rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire sof, eof,
    output wire [7:0] data_out,
    output wire tx_valid,
    output wire packet_done
);
    // 状态定义
    localparam IDLE=3'd0, HEADER=3'd1, PAYLOAD=3'd2, 
               CRC=3'd3, TRAILER=3'd4, DONE=3'd5;
    
    // 寄存器定义
    reg [2:0] state_r, next_state;
    reg [7:0] frame_header_r;
    reg [7:0] byte_count_r;
    reg [15:0] crc_r;
    reg [7:0] data_out_r;
    reg tx_valid_r;
    reg packet_done_r;
    
    // 组合逻辑输出连接
    assign data_out = data_out_r;
    assign tx_valid = tx_valid_r;
    assign packet_done = packet_done_r;
    
    // 组合逻辑：状态转移
    always @(*) begin
        case (state_r)
            IDLE:    next_state = sof ? HEADER : IDLE;
            HEADER:  next_state = PAYLOAD;
            PAYLOAD: next_state = eof ? CRC : PAYLOAD;
            CRC:     next_state = (byte_count_r[0]) ? TRAILER : CRC;
            TRAILER: next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 组合逻辑：输出和数据路径计算
    reg [7:0] data_out_next;
    reg tx_valid_next;
    reg packet_done_next;
    reg [7:0] byte_count_next;
    reg [15:0] crc_next;
    
    always @(*) begin
        // 默认保持当前值
        data_out_next = data_out_r;
        tx_valid_next = tx_valid_r;
        packet_done_next = packet_done_r;
        byte_count_next = byte_count_r;
        crc_next = crc_r;
        
        case (state_r)
            IDLE: begin
                tx_valid_next = 1'b0;
                packet_done_next = 1'b0;
                byte_count_next = 8'd0;
                crc_next = 16'd0;
            end
            HEADER: begin
                data_out_next = frame_header_r;
                tx_valid_next = 1'b1;
            end
            PAYLOAD: begin
                if (data_valid) begin
                    data_out_next = data_in;
                    tx_valid_next = 1'b1;
                    byte_count_next = byte_count_r + 8'd1;
                    crc_next = crc_r ^ {8'd0, data_in};
                end else begin
                    tx_valid_next = 1'b0;
                end
            end
            CRC: begin
                case (byte_count_r[0])
                    1'b0: begin 
                        data_out_next = crc_r[7:0]; 
                        tx_valid_next = 1'b1; 
                    end
                    1'b1: begin 
                        data_out_next = crc_r[15:8]; 
                        tx_valid_next = 1'b1; 
                    end
                endcase
                byte_count_next = byte_count_r + 8'd1;
            end
            TRAILER: begin
                data_out_next = 8'h5A; // Fixed frame trailer
                tx_valid_next = 1'b1;
            end
            DONE: begin
                tx_valid_next = 1'b0;
                packet_done_next = 1'b1;
            end
        endcase
    end
    
    // 时序逻辑：寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            state_r <= IDLE;
            frame_header_r <= 8'hA5; // Fixed frame header
            byte_count_r <= 8'd0;
            crc_r <= 16'd0;
            tx_valid_r <= 1'b0;
            packet_done_r <= 1'b0;
            data_out_r <= 8'h0;
        end else begin
            state_r <= next_state;
            data_out_r <= data_out_next;
            tx_valid_r <= tx_valid_next;
            packet_done_r <= packet_done_next;
            byte_count_r <= byte_count_next;
            crc_r <= crc_next;
        end
    end
    
endmodule