//SystemVerilog
module usb_token_builder(
    input wire clk,
    input wire rst_n,
    input wire build_enable,
    input wire [1:0] token_type,
    input wire [6:0] device_address,
    input wire [3:0] endpoint_number,
    output reg [15:0] token_packet,
    output reg token_ready,
    output reg [4:0] crc_value,
    output reg [1:0] builder_state
);
    // Token type definitions
    localparam OUT_TOKEN = 2'b00;
    localparam IN_TOKEN = 2'b01;
    localparam SETUP_TOKEN = 2'b10;
    localparam SOF_TOKEN = 2'b11;
    
    // PID values
    localparam OUT_PID = 8'b00011110;   // 0x1E (complemented OUT)
    localparam IN_PID = 8'b10010110;    // 0x96 (complemented IN)
    localparam SETUP_PID = 8'b10110110; // 0xB6 (complemented SETUP)
    localparam SOF_PID = 8'b10100110;   // 0xA6 (complemented SOF)
    
    // Builder state machine with Gray code encoding
    localparam IDLE = 2'b00;      // 00 -> Gray code
    localparam GENERATE = 2'b01;  // 01 -> Gray code
    localparam PIPELINE = 2'b10;  // 10 -> Gray code (Added pipeline state)
    localparam COMPLETE = 2'b11;  // 11 -> Gray code
    
    // Token packet format: PID + ADDRESS/ENDPOINT + CRC5
    reg [7:0] pid;
    reg [10:0] addr_endp;  // 7-bit address + 4-bit endpoint
    
    // Buffer registers for high fan-out signal addr_endp
    reg [10:0] addr_endp_buf1;
    reg [10:0] addr_endp_buf2;
    
    // Pipeline registers for CRC calculation
    reg [4:0] crc_partial1;
    reg [4:0] crc_partial2;
    
    // Intermediate signals for CRC calculation
    wire [4:0] crc_stage1;
    
    // First stage of CRC calculation
    assign crc_stage1[0] = addr_endp[10] ^ addr_endp[8] ^ addr_endp[6];
    assign crc_stage1[1] = addr_endp[9] ^ addr_endp[7] ^ addr_endp[5];
    assign crc_stage1[2] = addr_endp[8] ^ addr_endp[6] ^ addr_endp[4];
    assign crc_stage1[3] = addr_endp[7] ^ addr_endp[5] ^ addr_endp[3];
    assign crc_stage1[4] = addr_endp[6] ^ addr_endp[4] ^ addr_endp[2];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            builder_state <= IDLE;
            token_packet <= 16'h0000;
            token_ready <= 1'b0;
            crc_value <= 5'h00;
            pid <= 8'h00;
            addr_endp <= 11'h000;
            addr_endp_buf1 <= 11'h000;
            addr_endp_buf2 <= 11'h000;
            crc_partial1 <= 5'h00;
            crc_partial2 <= 5'h00;
        end else begin
            case (builder_state)
                IDLE: begin
                    token_ready <= 1'b0;
                    if (build_enable) begin
                        builder_state <= GENERATE;
                        // Select PID based on token type
                        case (token_type)
                            OUT_TOKEN:   pid <= OUT_PID;
                            IN_TOKEN:    pid <= IN_PID;
                            SETUP_TOKEN: pid <= SETUP_PID;
                            SOF_TOKEN:   pid <= SOF_PID;
                        endcase
                        
                        // Prepare the address/endpoint field
                        addr_endp <= {device_address, endpoint_number};
                            
                        // Buffer the addr_endp signal to reduce fan-out
                        addr_endp_buf1 <= {device_address, endpoint_number};
                        addr_endp_buf2 <= {device_address, endpoint_number};
                    end
                end
                
                GENERATE: begin
                    // First stage of pipelined CRC calculation
                    crc_partial1 <= crc_stage1;
                    
                    // Store addr_endp for next stage
                    addr_endp_buf1 <= addr_endp;
                    addr_endp_buf2 <= addr_endp_buf1;
                    
                    builder_state <= PIPELINE;
                end
                
                PIPELINE: begin
                    // Second stage of pipelined CRC calculation
                    crc_value[0] <= crc_partial1[0] ^ addr_endp_buf1[4] ^ addr_endp_buf1[2] ^ addr_endp_buf1[0];
                    crc_value[1] <= crc_partial1[1] ^ addr_endp_buf1[3] ^ addr_endp_buf1[1];
                    crc_value[2] <= crc_partial1[2] ^ addr_endp_buf1[2] ^ addr_endp_buf1[0];
                    crc_value[3] <= crc_partial1[3] ^ addr_endp_buf1[1];
                    crc_value[4] <= crc_partial1[4] ^ addr_endp_buf1[0];
                    
                    // Form the complete token packet
                    token_packet <= {crc_value, addr_endp_buf2};
                    
                    builder_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    token_ready <= 1'b1;
                    builder_state <= IDLE;
                end
                
                default: begin
                    builder_state <= IDLE;
                end
            endcase
        end
    end
endmodule