//SystemVerilog
module packet_framer(
    input wire clk, rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire sof, eof,
    output reg [7:0] data_out,
    output reg tx_valid,
    output reg packet_done
);
    localparam IDLE=3'd0, HEADER=3'd1, PAYLOAD=3'd2, 
               CRC=3'd3, TRAILER=3'd4, DONE=3'd5;
    reg [2:0] state, next;
    reg [7:0] frame_header;
    reg [7:0] byte_count;
    reg [15:0] crc;
    reg [15:0] crc_next;
    
    // Optimized state transition logic
    always @(*) begin
        case (state)
            IDLE:    next = sof ? HEADER : IDLE;
            HEADER:  next = PAYLOAD;
            PAYLOAD: next = eof ? CRC : PAYLOAD;
            CRC:     next = (byte_count[0]) ? TRAILER : CRC;
            TRAILER: next = DONE;
            DONE:    next = IDLE;
            default: next = IDLE;
        endcase
    end

    // Optimized CRC calculation
    always @(*) begin
        crc_next = crc;
        if (state == PAYLOAD && data_valid) begin
            crc_next = crc ^ {8'd0, data_in};
        end
    end

    // Optimized data path
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            frame_header <= 8'hA5;
            byte_count <= 8'd0;
            crc <= 16'd0;
            tx_valid <= 1'b0;
            packet_done <= 1'b0;
            data_out <= 8'h0;
        end else begin
            state <= next;
            crc <= crc_next;
            
            // Default values
            tx_valid <= 1'b0;
            packet_done <= 1'b0;
            
            case (state)
                IDLE: begin
                    byte_count <= 8'd0;
                end
                
                HEADER: begin
                    data_out <= frame_header;
                    tx_valid <= 1'b1;
                end
                
                PAYLOAD: begin
                    if (data_valid) begin
                        data_out <= data_in;
                        tx_valid <= 1'b1;
                        byte_count <= byte_count + 8'd1;
                    end
                end
                
                CRC: begin
                    tx_valid <= 1'b1;
                    data_out <= byte_count[0] ? crc[15:8] : crc[7:0];
                    byte_count <= byte_count + 8'd1;
                end
                
                TRAILER: begin
                    data_out <= 8'h5A;
                    tx_valid <= 1'b1;
                end
                
                DONE: begin
                    packet_done <= 1'b1;
                end
            endcase
        end
    end
endmodule