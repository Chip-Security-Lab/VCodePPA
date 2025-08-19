module MIPI_PacketGenerator #(
    parameter PACKET_TYPE = 8'h18,
    parameter PAYLOAD_SIZE = 4
)(
    input wire clk,
    input wire rst,
    input wire trigger,
    output reg [7:0] packet_data,
    output reg packet_valid
);
    // 状态定义
    localparam IDLE = 2'd0;
    localparam HEADER = 2'd1;
    localparam PAYLOAD = 2'd2;
    localparam CRC = 2'd3;
    
    reg [1:0] current_state;
    reg [3:0] payload_counter;
    reg [7:0] crc;

    always @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
            packet_valid <= 0;
            payload_counter <= 0;
            packet_data <= 8'h00;
            crc <= 8'h00;
        end else begin
            case(current_state)
                IDLE: begin
                    if (trigger) begin
                        packet_data <= PACKET_TYPE;
                        packet_valid <= 1;
                        current_state <= HEADER;
                    end else begin
                        packet_valid <= 0;
                    end
                end
                
                HEADER: begin
                    packet_data <= PAYLOAD_SIZE;
                    current_state <= PAYLOAD;
                    payload_counter <= 0;
                end
                
                PAYLOAD: begin
                    if (payload_counter < PAYLOAD_SIZE) begin
                        packet_data <= 8'hA5 + payload_counter;
                        payload_counter <= payload_counter + 1;
                    end else begin
                        crc <= packet_data ^ 8'hFF;
                        current_state <= CRC;
                    end
                end
                
                CRC: begin
                    packet_data <= crc;
                    packet_valid <= 0;
                    current_state <= IDLE;
                end
                
                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end
endmodule