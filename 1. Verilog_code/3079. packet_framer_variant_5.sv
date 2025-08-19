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
    
    // State registers and pipeline stages
    reg [2:0] state, next;
    reg [7:0] frame_header;
    reg [7:0] byte_count, byte_count_next;
    reg [15:0] crc, crc_next;
    
    // Pipeline registers for CRC calculation
    reg [7:0] data_in_r;
    reg [15:0] crc_stage1;
    
    // Additional pipeline registers for control signals
    reg data_valid_r, eof_r, sof_r;
    
    // State logic - separated from data path
    always @(posedge clk)
        if (rst) begin
            state <= IDLE;
            frame_header <= 8'hA5; // Fixed frame header
        end else begin
            state <= next;
        end
    
    // Data path logic - pipelined
    always @(posedge clk)
        if (rst) begin
            byte_count <= 8'd0;
            crc <= 16'd0;
            tx_valid <= 1'b0;
            packet_done <= 1'b0;
            
            // Reset pipeline registers
            data_in_r <= 8'd0;
            crc_stage1 <= 16'd0;
            data_valid_r <= 1'b0;
            eof_r <= 1'b0;
            sof_r <= 1'b0;
        end else begin
            // First stage pipeline - register inputs
            data_in_r <= data_in;
            data_valid_r <= data_valid;
            eof_r <= eof;
            sof_r <= sof;
            
            // Second stage pipeline - CRC calculation stage 1
            if (state == PAYLOAD && data_valid_r)
                crc_stage1 <= crc ^ {8'd0, data_in_r};
            
            // Update actual crc with pipelined result
            crc <= crc_next;
            
            // Update byte counter
            byte_count <= byte_count_next;
            
            // Output control signals
            case (state)
                IDLE: begin
                    tx_valid <= 1'b0;
                    packet_done <= 1'b0;
                end
                HEADER: begin
                    data_out <= frame_header;
                    tx_valid <= 1'b1;
                end
                PAYLOAD: begin
                    if (data_valid_r) begin
                        data_out <= data_in_r;
                        tx_valid <= 1'b1;
                    end else
                        tx_valid <= 1'b0;
                end
                CRC: begin
                    case (byte_count[0])
                        1'b0: begin data_out <= crc[7:0]; tx_valid <= 1'b1; end
                        1'b1: begin data_out <= crc[15:8]; tx_valid <= 1'b1; end
                    endcase
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
    
    // Combinational logic for next values
    always @(*) begin
        // Default assignments
        byte_count_next = byte_count;
        crc_next = crc;
        
        case (state)
            IDLE: begin
                byte_count_next = 8'd0;
                crc_next = 16'd0;
            end
            PAYLOAD: begin
                if (data_valid_r) begin
                    byte_count_next = byte_count + 8'd1;
                    crc_next = crc_stage1; // Use pipelined CRC value
                end
            end
            CRC: begin
                byte_count_next = byte_count + 8'd1;
            end
            default: begin
                // Maintain current values
            end
        endcase
    end
    
    // State transition logic
    always @(*)
        case (state)
            IDLE: next = sof_r ? HEADER : IDLE;
            HEADER: next = PAYLOAD;
            PAYLOAD: next = eof_r ? CRC : PAYLOAD;
            CRC: next = (byte_count[0]) ? TRAILER : CRC;
            TRAILER: next = DONE;
            DONE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule