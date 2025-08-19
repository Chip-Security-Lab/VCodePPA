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
    
    // Builder state machine
    localparam IDLE = 2'b00;
    localparam GENERATE = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Token packet format: PID + ADDRESS/ENDPOINT + CRC5
    reg [7:0] pid;
    reg [10:0] addr_endp;  // 7-bit address + 4-bit endpoint
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            builder_state <= IDLE;
            token_packet <= 16'h0000;
            token_ready <= 1'b0;
            crc_value <= 5'h00;
            pid <= 8'h00;
            addr_endp <= 11'h000;
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
                        if (token_type == SOF_TOKEN)
                            addr_endp <= {device_address, endpoint_number}; // For SOF, this is frame number
                        else
                            addr_endp <= {device_address, endpoint_number};
                    end
                end
                GENERATE: begin
                    // Generate CRC5 (simplified - actual implementation would use XOR network)
                    crc_value <= {addr_endp[10] ^ addr_endp[8] ^ addr_endp[6] ^ addr_endp[4] ^ addr_endp[2] ^ addr_endp[0],
                                addr_endp[9] ^ addr_endp[7] ^ addr_endp[5] ^ addr_endp[3] ^ addr_endp[1],
                                addr_endp[8] ^ addr_endp[6] ^ addr_endp[4] ^ addr_endp[2] ^ addr_endp[0],
                                addr_endp[7] ^ addr_endp[5] ^ addr_endp[3] ^ addr_endp[1],
                                addr_endp[6] ^ addr_endp[4] ^ addr_endp[2] ^ addr_endp[0]};
                    
                    // Form the complete token packet
                    token_packet <= {crc_value, addr_endp};
                    builder_state <= COMPLETE;
                end
                COMPLETE: begin
                    token_ready <= 1'b1;
                    builder_state <= IDLE;
                end
            endcase
        end
    end
endmodule