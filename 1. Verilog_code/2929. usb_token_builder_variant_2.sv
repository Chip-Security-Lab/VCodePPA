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
    
    // Builder state machine
    localparam IDLE = 2'b00;
    localparam GENERATE = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Registered inputs to reduce input-to-register delay
    reg [1:0] token_type_r;
    reg [6:0] device_address_r;
    reg [3:0] endpoint_number_r;
    reg build_enable_r;
    
    // Token packet components
    reg [7:0] pid;
    reg [10:0] addr_endp;
    
    // CRC calculation - Optimized using parity equations
    // Using simplified boolean expressions with reduced XOR chains
    wire [4:0] crc_computed;
    
    // Simplified bit-even parity functions for CRC calculation
    wire even_parity_bit0, even_parity_bit1, even_parity_bit2;
    
    // Compute parity of even-indexed bits (0,2,4,6,8,10)
    assign even_parity_bit0 = addr_endp[0] ^ addr_endp[2] ^ addr_endp[4] ^ addr_endp[6] ^ addr_endp[8] ^ addr_endp[10];
    
    // Compute parity of odd-indexed bits (1,3,5,7,9)
    assign even_parity_bit1 = addr_endp[1] ^ addr_endp[3] ^ addr_endp[5] ^ addr_endp[7] ^ addr_endp[9];
    
    // Compute parity of even-indexed bits except bit 10 (0,2,4,6,8)
    assign even_parity_bit2 = addr_endp[0] ^ addr_endp[2] ^ addr_endp[4] ^ addr_endp[6] ^ addr_endp[8];
    
    // CRC computation using the parity results - reduced gate count implementation
    assign crc_computed[0] = even_parity_bit0;
    assign crc_computed[1] = even_parity_bit1;
    assign crc_computed[2] = even_parity_bit2;
    assign crc_computed[3] = addr_endp[1] ^ addr_endp[3] ^ addr_endp[5] ^ addr_endp[7];
    assign crc_computed[4] = addr_endp[0] ^ addr_endp[2] ^ addr_endp[4] ^ addr_endp[6];
    
    // Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_type_r <= 2'b00;
            device_address_r <= 7'h00;
            endpoint_number_r <= 4'h0;
            build_enable_r <= 1'b0;
        end else begin
            token_type_r <= token_type;
            device_address_r <= device_address;
            endpoint_number_r <= endpoint_number;
            build_enable_r <= build_enable;
        end
    end
    
    // Main state machine with forward-retimed registers
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
                    
                    if (build_enable_r) begin
                        builder_state <= GENERATE;
                        
                        // Simplified PID selection
                        pid <= (token_type_r == OUT_TOKEN) ? OUT_PID :
                               (token_type_r == IN_TOKEN) ? IN_PID :
                               (token_type_r == SETUP_TOKEN) ? SETUP_PID : SOF_PID;
                        
                        // Compact address/endpoint field construction
                        addr_endp <= {device_address_r, endpoint_number_r};
                    end
                end
                
                GENERATE: begin
                    // Store CRC value with reduced critical path
                    crc_value <= crc_computed;
                    
                    // Form complete token packet in one cycle
                    token_packet <= {crc_computed, addr_endp};
                    builder_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    token_ready <= 1'b1;
                    builder_state <= IDLE;
                end
                
                default: begin
                    // Safe recovery
                    builder_state <= IDLE;
                end
            endcase
        end
    end
endmodule