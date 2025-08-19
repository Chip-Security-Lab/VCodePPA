//SystemVerilog - IEEE 1364-2005
module usb_token_builder(
    // Global signals
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
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
    
    // Builder state machine - increased pipeline states
    localparam IDLE = 3'b000;
    localparam PREPARE = 3'b001;
    localparam GENERATE_1 = 3'b010;
    localparam GENERATE_2 = 3'b011;
    localparam ASSEMBLE = 3'b100;
    localparam COMPLETE = 3'b101;
    
    // AXI response types
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERROR = 2'b10;
    
    // Register addresses (byte addressed)
    localparam ADDR_CONTROL     = 4'h0; // Control register: bit[0]=build_enable, bits[2:1]=token_type
    localparam ADDR_DEVICE_ENDP = 4'h4; // Device/Endpoint: bits[6:0]=device_address, bits[11:8]=endpoint_number
    localparam ADDR_STATUS      = 4'h8; // Status: bit[0]=token_ready, bits[5:1]=crc_value, bits[7:6]=builder_state
    localparam ADDR_TOKEN       = 4'hC; // Token packet data
    
    // Internal registers
    reg build_enable;
    reg [1:0] token_type;
    reg [6:0] device_address;
    reg [3:0] endpoint_number;
    reg [15:0] token_packet;
    reg token_ready;
    reg [4:0] crc_value;
    reg [2:0] builder_state;
    
    // Token packet format: PID + ADDRESS/ENDPOINT + CRC5
    reg [7:0] pid_stage1;
    reg [7:0] pid_stage2;
    reg [7:0] pid_stage3;
    
    reg [10:0] addr_endp_stage1;  // 7-bit address + 4-bit endpoint in stage 1
    reg [10:0] addr_endp_stage2;  // Stage 2 register
    reg [10:0] addr_endp_stage3;  // Stage 3 register
    
    // Pipeline control registers
    reg build_active_stage1;
    reg build_active_stage2;
    reg build_active_stage3;
    reg build_active_stage4;
    
    // Input capture registers (multi-stage pipeline for timing optimization)
    reg s_axil_awvalid_r;
    reg [31:0] s_axil_awaddr_r;
    reg s_axil_wvalid_r;
    reg [31:0] s_axil_wdata_r;
    reg [3:0] s_axil_wstrb_r;
    reg s_axil_bready_r;
    reg s_axil_arvalid_r;
    reg [31:0] s_axil_araddr_r;
    reg s_axil_rready_r;
    
    // CRC pipeline registers
    reg [4:0] crc_bits_stage1;
    reg [4:0] crc_bits_stage2;
    reg [4:0] crc_bits_stage3;
    
    // Intermediate CRC computation signals
    reg [10:0] input_bits_stage1;
    reg [4:0] partial_crc_stage1; 
    reg [4:0] partial_crc_stage2;
    
    // Pre-register input signals to improve timing
    always @(posedge clk) begin
        s_axil_awvalid_r <= s_axil_awvalid;
        s_axil_awaddr_r <= s_axil_awaddr;
        s_axil_wvalid_r <= s_axil_wvalid;
        s_axil_wdata_r <= s_axil_wdata;
        s_axil_wstrb_r <= s_axil_wstrb;
        s_axil_bready_r <= s_axil_bready;
        s_axil_arvalid_r <= s_axil_arvalid;
        s_axil_araddr_r <= s_axil_araddr;
        s_axil_rready_r <= s_axil_rready;
    end

    // Write address channel handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
        end else begin
            if (s_axil_awvalid_r && !s_axil_awready)
                s_axil_awready <= 1'b1;
            else
                s_axil_awready <= 1'b0;
        end
    end

    // Write data channel handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_wready <= 1'b0;
            build_enable <= 1'b0;
            token_type <= 2'b00;
            device_address <= 7'h00;
            endpoint_number <= 4'h0;
        end else begin
            if (s_axil_wvalid_r && !s_axil_wready) begin
                s_axil_wready <= 1'b1;
                
                // Write to appropriate register based on address
                case (s_axil_awaddr_r[3:0])
                    ADDR_CONTROL: begin
                        if (s_axil_wstrb_r[0]) begin
                            build_enable <= s_axil_wdata_r[0];
                            token_type <= s_axil_wdata_r[2:1];
                        end
                    end
                    ADDR_DEVICE_ENDP: begin
                        if (s_axil_wstrb_r[0]) begin
                            device_address <= s_axil_wdata_r[6:0];
                        end
                        if (s_axil_wstrb_r[1]) begin
                            endpoint_number <= s_axil_wdata_r[11:8];
                        end
                    end
                    default: begin
                        // Other registers are read-only
                    end
                endcase
            end else begin
                s_axil_wready <= 1'b0;
                // Auto-clear build_enable after being set
                if (builder_state == COMPLETE) begin
                    build_enable <= 1'b0;
                end
            end
        end
    end

    // Write response channel handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
        end else begin
            if (s_axil_wready && s_axil_wvalid_r && s_axil_awready && s_axil_awvalid_r && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= RESP_OKAY; // Always respond with OKAY
            end else if (s_axil_bvalid && s_axil_bready_r) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // Read address channel handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
        end else begin
            if (s_axil_arvalid_r && !s_axil_arready)
                s_axil_arready <= 1'b1;
            else
                s_axil_arready <= 1'b0;
        end
    end

    // Read data channel handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h00000000;
        end else begin
            if (s_axil_arready && s_axil_arvalid_r && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= RESP_OKAY; // Always respond with OKAY
                
                // Return data based on requested address
                case (s_axil_araddr_r[3:0])
                    ADDR_CONTROL: 
                        s_axil_rdata <= {29'h0, token_type, build_enable};
                    ADDR_DEVICE_ENDP:
                        s_axil_rdata <= {20'h0, endpoint_number, 1'b0, device_address};
                    ADDR_STATUS:
                        s_axil_rdata <= {24'h0, builder_state[1:0], crc_value, token_ready};
                    ADDR_TOKEN:
                        s_axil_rdata <= {16'h0, token_packet};
                    default:
                        s_axil_rdata <= 32'h00000000;
                endcase
            end else if (s_axil_rvalid && s_axil_rready_r) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

    // Pipeline Stage 1: Initial setup and partial CRC computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            builder_state <= IDLE;
            build_active_stage1 <= 1'b0;
            addr_endp_stage1 <= 11'h0;
            pid_stage1 <= 8'h0;
            partial_crc_stage1 <= 5'h0;
            input_bits_stage1 <= 11'h0;
        end else begin
            case (builder_state)
                IDLE: begin
                    if (build_enable) begin
                        builder_state <= PREPARE;
                        build_active_stage1 <= 1'b1;
                        
                        // Select PID based on token type
                        case (token_type)
                            OUT_TOKEN:   pid_stage1 <= OUT_PID;
                            IN_TOKEN:    pid_stage1 <= IN_PID;
                            SETUP_TOKEN: pid_stage1 <= SETUP_PID;
                            SOF_TOKEN:   pid_stage1 <= SOF_PID;
                        endcase
                        
                        // Form addr_endp early in pipeline
                        if (token_type == SOF_TOKEN)
                            addr_endp_stage1 <= {device_address, endpoint_number}; // For SOF, this is frame number
                        else
                            addr_endp_stage1 <= {device_address, endpoint_number};
                            
                        // Prepare input bits for CRC calculation
                        input_bits_stage1 <= {device_address, endpoint_number};
                        
                        // First part of CRC5 calculation (XOR operations for bits 0,2,4,6,8,10)
                        partial_crc_stage1[0] <= device_address[6] ^ endpoint_number[2] ^ device_address[4] ^ 
                                                 device_address[2] ^ device_address[0] ^ endpoint_number[0];
                    end else begin
                        build_active_stage1 <= 1'b0;
                    end
                end
                
                PREPARE: begin
                    builder_state <= GENERATE_1;
                end
                
                GENERATE_1: begin
                    builder_state <= GENERATE_2;
                end
                
                GENERATE_2: begin
                    builder_state <= ASSEMBLE;
                end
                
                ASSEMBLE: begin
                    builder_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    if (!build_enable) begin
                        builder_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // Pipeline Stage 2: Continue CRC calculation and propagate values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            build_active_stage2 <= 1'b0;
            addr_endp_stage2 <= 11'h0;
            pid_stage2 <= 8'h0;
            partial_crc_stage2 <= 5'h0;
        end else begin
            build_active_stage2 <= build_active_stage1;
            addr_endp_stage2 <= addr_endp_stage1;
            pid_stage2 <= pid_stage1;
            
            if (build_active_stage1) begin
                // Continue CRC5 calculation, second part (XOR operations for bits 1,3,5,7,9)
                partial_crc_stage2[0] <= partial_crc_stage1[0];
                partial_crc_stage2[1] <= addr_endp_stage1[9] ^ addr_endp_stage1[7] ^ 
                                       addr_endp_stage1[5] ^ addr_endp_stage1[3] ^ addr_endp_stage1[1];
                partial_crc_stage2[2] <= addr_endp_stage1[8] ^ addr_endp_stage1[6] ^ 
                                       addr_endp_stage1[4] ^ addr_endp_stage1[2] ^ addr_endp_stage1[0];
            end
        end
    end
    
    // Pipeline Stage 3: Complete CRC calculation and prepare for final assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            build_active_stage3 <= 1'b0;
            addr_endp_stage3 <= 11'h0;
            pid_stage3 <= 8'h0;
            crc_bits_stage3 <= 5'h0;
        end else begin
            build_active_stage3 <= build_active_stage2;
            addr_endp_stage3 <= addr_endp_stage2;
            pid_stage3 <= pid_stage2;
            
            if (build_active_stage2) begin
                // Complete CRC5 calculation
                crc_bits_stage3[0] <= partial_crc_stage2[0];
                crc_bits_stage3[1] <= partial_crc_stage2[1];
                crc_bits_stage3[2] <= partial_crc_stage2[2];
                crc_bits_stage3[3] <= addr_endp_stage2[7] ^ addr_endp_stage2[5] ^ 
                                    addr_endp_stage2[3] ^ addr_endp_stage2[1];
                crc_bits_stage3[4] <= addr_endp_stage2[6] ^ addr_endp_stage2[4] ^ 
                                    addr_endp_stage2[2] ^ addr_endp_stage2[0];
            end
        end
    end
    
    // Pipeline Stage 4: Final assembly of token packet
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            build_active_stage4 <= 1'b0;
            token_packet <= 16'h0000;
            token_ready <= 1'b0;
            crc_value <= 5'h00;
        end else begin
            build_active_stage4 <= build_active_stage3;
            
            if (build_active_stage3) begin
                // Assemble final token packet
                token_packet <= {crc_bits_stage3, addr_endp_stage3};
                crc_value <= crc_bits_stage3;
            end
            
            // Set token ready flag at the appropriate pipeline stage
            if (builder_state == COMPLETE) begin
                token_ready <= 1'b1;
            end else if (builder_state == IDLE) begin
                token_ready <= 1'b0;
            end
        end
    end
endmodule