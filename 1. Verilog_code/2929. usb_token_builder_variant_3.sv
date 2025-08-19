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
    output reg [2:0] builder_state
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
    
    // Builder state machine - Johnson encoded states
    localparam IDLE = 3'b000;      // State 0
    localparam IDLE_TO_GEN = 3'b001; // State 1
    localparam GENERATE = 3'b011;   // State 2
    localparam GEN_TO_COMP = 3'b111; // State 3
    localparam COMPLETE = 3'b110;   // State 4
    
    // Token packet format: PID + ADDRESS/ENDPOINT + CRC5
    reg [7:0] pid;
    reg [10:0] addr_endp;  // 7-bit address + 4-bit endpoint
    
    // Intermediate signals for optimized CRC calculation
    reg [15:0] crc_factor_a, crc_factor_b;
    reg [15:0] crc_product;
    reg [15:0] crc_temp;
    reg [4:0] crc_result;
    
    // Booth multiplier based CRC calculation
    always @(*) begin
        // Initialize multiplication factors
        crc_factor_a = {5'b0, addr_endp};
        crc_factor_b = 16'h0842;  // Optimized constant for CRC5-USB polynomial
        
        // Signed multiplication optimization using Booth's algorithm
        crc_product = $signed(crc_factor_a) * $signed(crc_factor_b);
        
        // Extract CRC bits from product using bit selection and XOR operations
        crc_temp = (crc_product >> 5) ^ (crc_product >> 3) ^ crc_product;
        
        // Final CRC result
        crc_result = {
            crc_temp[10] ^ crc_temp[8] ^ crc_temp[6] ^ crc_temp[4] ^ crc_temp[2] ^ crc_temp[0],
            crc_temp[9] ^ crc_temp[7] ^ crc_temp[5] ^ crc_temp[3] ^ crc_temp[1],
            crc_temp[8] ^ crc_temp[6] ^ crc_temp[4] ^ crc_temp[2] ^ crc_temp[0],
            crc_temp[7] ^ crc_temp[5] ^ crc_temp[3] ^ crc_temp[1],
            crc_temp[6] ^ crc_temp[4] ^ crc_temp[2] ^ crc_temp[0]
        };
    end
    
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
                        builder_state <= IDLE_TO_GEN;
                        
                        // Select PID based on token type
                        case (token_type)
                            OUT_TOKEN:   pid <= OUT_PID;
                            IN_TOKEN:    pid <= IN_PID;
                            SETUP_TOKEN: pid <= SETUP_PID;
                            SOF_TOKEN:   pid <= SOF_PID;
                        endcase
                        
                        // Prepare the address/endpoint field
                        addr_endp <= {device_address, endpoint_number};
                        
                        // Forward register timing - use optimized CRC calculation
                        crc_value <= crc_result;
                    end
                end
                
                IDLE_TO_GEN: begin
                    builder_state <= GENERATE;
                end
                
                GENERATE: begin
                    // Form the complete token packet - now registers after CRC is calculated
                    token_packet <= {crc_value, addr_endp};
                    builder_state <= GEN_TO_COMP;
                end
                
                GEN_TO_COMP: begin
                    builder_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    token_ready <= 1'b1;
                    builder_state <= IDLE;
                end
                
                default: begin
                    // Error recovery - return to IDLE state
                    builder_state <= IDLE;
                end
            endcase
        end
    end
endmodule