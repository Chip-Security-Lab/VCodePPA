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

    // 状态定义 - 使用one-hot编码提高性能
    localparam IDLE = 3'b001;
    localparam HEADER = 3'b010;
    localparam PAYLOAD = 3'b100;
    localparam CRC = 3'b000;
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [3:0] payload_counter;
    reg [3:0] next_payload_counter;
    reg [7:0] crc;
    reg [7:0] next_crc;
    reg [7:0] next_packet_data;
    reg next_packet_valid;
    
    // 状态寄存器 - 使用非阻塞赋值提高性能
    always @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
            payload_counter <= 4'b0;
            crc <= 8'h00;
            packet_data <= 8'h00;
            packet_valid <= 1'b0;
        end else begin
            current_state <= next_state;
            payload_counter <= next_payload_counter;
            crc <= next_crc;
            packet_data <= next_packet_data;
            packet_valid <= next_packet_valid;
        end
    end

    // 组合逻辑 - 优化比较操作
    always @(*) begin
        // 默认值
        next_state = current_state;
        next_payload_counter = payload_counter;
        next_crc = crc;
        next_packet_data = packet_data;
        next_packet_valid = packet_valid;

        case(1'b1) // 使用one-hot编码的case语句提高性能
            current_state[0]: begin // IDLE
                if (trigger) begin
                    next_packet_data = PACKET_TYPE;
                    next_packet_valid = 1'b1;
                    next_state = HEADER;
                end else begin
                    next_packet_valid = 1'b0;
                end
            end
            
            current_state[1]: begin // HEADER
                next_packet_data = PAYLOAD_SIZE;
                next_state = PAYLOAD;
                next_payload_counter = 4'b0;
            end
            
            current_state[2]: begin // PAYLOAD
                // 使用范围检查优化比较操作
                if (payload_counter < PAYLOAD_SIZE) begin
                    next_packet_data = 8'hA5 + payload_counter;
                    next_payload_counter = payload_counter + 4'b1;
                end else begin
                    // 优化CRC计算
                    next_crc = packet_data ^ 8'hFF;
                    next_state = CRC;
                end
            end
            
            default: begin // CRC或未知状态
                if (current_state == CRC) begin
                    next_packet_data = crc;
                    next_packet_valid = 1'b0;
                    next_state = IDLE;
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule