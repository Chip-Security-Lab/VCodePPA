//SystemVerilog
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
    // 状态定义 - 使用约翰逊编码
    localparam IDLE = 3'b000;
    localparam HEADER = 3'b001;
    localparam PAYLOAD = 3'b011;
    localparam CRC = 3'b111;
    localparam WAIT = 3'b110;
    
    reg [2:0] current_state;
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
                    current_state <= WAIT;
                end
                
                WAIT: begin
                    current_state <= IDLE;
                end
                
                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end
endmodule