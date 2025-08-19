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
    
    always @(posedge clk)
        if (rst) begin
            state <= IDLE;
            frame_header <= 8'hA5; // Fixed frame header
            byte_count <= 8'd0;
            crc <= 16'd0;
            tx_valid <= 1'b0;
            packet_done <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    tx_valid <= 1'b0;
                    packet_done <= 1'b0;
                    byte_count <= 8'd0;
                    crc <= 16'd0;
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
                        // Simple CRC calculation for example
                        crc <= crc ^ {8'd0, data_in};
                    end else
                        tx_valid <= 1'b0;
                end
                CRC: begin
                    case (byte_count[0])
                        1'b0: begin data_out <= crc[7:0]; tx_valid <= 1'b1; end
                        1'b1: begin data_out <= crc[15:8]; tx_valid <= 1'b1; end
                    endcase
                    byte_count <= byte_count + 8'd1;
                end
                TRAILER: begin
                    data_out <= 8'h5A; // Fixed frame trailer
                    tx_valid <= 1'b1;
                end
                DONE: begin
                    tx_valid <= 1'b0;
                    packet_done <= 1'b1;
                end
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = sof ? HEADER : IDLE;
            HEADER: next = PAYLOAD;
            PAYLOAD: next = eof ? CRC : PAYLOAD;
            CRC: next = (byte_count[0]) ? TRAILER : CRC;
            TRAILER: next = DONE;
            DONE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule
