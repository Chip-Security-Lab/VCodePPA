module PacketParser #(
    parameter CRC_POLY = 32'h04C11DB7
)(
    input clk, rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_result,
    output reg packet_valid
);
    // 使用localparam代替typedef enum
    localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, CRC_CHECK = 2'b11;
    reg [1:0] current_state, next_state;
    
    reg [31:0] crc_reg;
    reg [3:0] byte_counter;

    // 修改CRC计算函数为Verilog兼容的语法
    function [31:0] calc_crc;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] result;
        integer i;
        begin
            result = crc;
            for (i=0; i<8; i=i+1) begin
                if ((data[7-i] ^ result[31]) == 1'b1)
                    result = (result << 1) ^ CRC_POLY;
                else
                    result = result << 1;
            end
            calc_crc = result;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            crc_reg <= 32'hFFFFFFFF;
            byte_counter <= 0;
            crc_result <= 0;
            packet_valid <= 0;
        end else begin
            current_state <= next_state;
            packet_valid <= 0; // 默认复位packet_valid
            
            if (data_valid) begin
                case(current_state)
                    HEADER: begin
                        if (byte_counter == 3) begin
                            byte_counter <= 0;
                        end else begin
                            byte_counter <= byte_counter + 1;
                        end
                    end
                    PAYLOAD: crc_reg <= calc_crc(data_in, crc_reg);
                    CRC_CHECK: begin
                        crc_result <= crc_reg;
                        packet_valid <= (crc_reg == 32'h0);
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (data_in == 8'h55 && data_valid) next_state = HEADER;
            HEADER: if (byte_counter == 3 && data_valid) next_state = PAYLOAD;
            PAYLOAD: if (data_in == 8'hAA && data_valid) next_state = CRC_CHECK;
            CRC_CHECK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule