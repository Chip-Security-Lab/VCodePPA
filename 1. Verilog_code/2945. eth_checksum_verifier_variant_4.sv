//SystemVerilog
module eth_checksum_verifier (
    // Clock and Reset
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // Internal registers for memory-mapped interface
    reg [7:0] rx_byte_reg;
    reg data_valid_reg;
    reg packet_start_reg;
    reg packet_end_reg;
    reg [15:0] checksum;
    reg [15:0] computed_checksum;
    reg [2:0] state;
    reg [9:0] byte_count;
    reg checksum_ok_reg;
    reg checksum_valid_reg;
    
    // AXI4-Lite address decoder - use localparam for better synthesis
    localparam ADDR_RX_BYTE      = 4'h0;
    localparam ADDR_CONTROL      = 4'h1;
    localparam ADDR_STATUS       = 4'h2;
    
    // State machine parameters - use one-hot encoding for better timing
    localparam IDLE      = 3'b001; 
    localparam HEADER    = 3'b010;
    localparam DATA      = 3'b100;
    localparam CHECKSUM_L = 3'd3;
    localparam CHECKSUM_H = 3'd4;
    
    // Write operation state machine - one-hot encoded
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b01;
    localparam WRITE_ADDR = 2'b10; 
    localparam WRITE_RESP = 2'b11;
    
    // Read operation state machine - one-hot encoded
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b01;
    localparam READ_ADDR = 2'b10;
    localparam READ_DATA = 2'b11;
    
    // Address decode registers
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    
    // Simplified wires for state transitions
    wire write_addr_handshake = s_axi_awvalid && s_axi_awready;
    wire write_data_handshake = s_axi_wvalid && s_axi_wready;
    wire write_resp_handshake = s_axi_bready && s_axi_bvalid;
    wire read_addr_handshake = s_axi_arvalid && s_axi_arready;
    wire read_data_handshake = s_axi_rready && s_axi_rvalid;
    
    // AXI Write state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            write_addr <= 4'h0;
            
            rx_byte_reg <= 8'h0;
            data_valid_reg <= 1'b0;
            packet_start_reg <= 1'b0;
            packet_end_reg <= 1'b0;
        end else begin
            // Default values
            data_valid_reg <= 1'b0;
            
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b1;
                    if (write_addr_handshake) begin
                        write_addr <= s_axi_awaddr[5:2];
                        s_axi_awready <= 1'b0;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (write_data_handshake) begin
                        s_axi_wready <= 1'b0;
                        
                        // Register write operations - case priority encoder
                        if (write_addr == ADDR_RX_BYTE) begin
                            rx_byte_reg <= s_axi_wdata[7:0];
                            data_valid_reg <= 1'b1;
                        end else if (write_addr == ADDR_CONTROL) begin
                            packet_start_reg <= s_axi_wdata[0];
                            packet_end_reg <= s_axi_wdata[1];
                        end
                        
                        s_axi_bresp <= 2'b00;  // OKAY response
                        s_axi_bvalid <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (write_resp_handshake) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI Read state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            read_addr <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (read_addr_handshake) begin
                        read_addr <= s_axi_araddr[5:2];
                        s_axi_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00;  // OKAY response
                    
                    // Register read operations - optimized case structure
                    case (read_addr)
                        ADDR_RX_BYTE: s_axi_rdata <= {24'h0, rx_byte_reg};
                        ADDR_CONTROL: s_axi_rdata <= {30'h0, packet_end_reg, packet_start_reg};
                        ADDR_STATUS:  s_axi_rdata <= {30'h0, checksum_valid_reg, checksum_ok_reg};
                        default:      s_axi_rdata <= 32'h00000000;
                    endcase
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (read_data_handshake) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Optimized signals for checksum verification state machine
    wire is_header_complete = (byte_count == 10'd13);
    wire [15:0] reconstructed_checksum = {rx_byte_reg, checksum[7:0]};
    
    // Core checksum verification logic - optimized state transitions
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= IDLE;
            byte_count <= 10'd0;
            checksum <= 16'd0;
            computed_checksum <= 16'd0;
            checksum_ok_reg <= 1'b0;
            checksum_valid_reg <= 1'b0;
        end else begin
            // Priority-based state transitions
            if (packet_start_reg) begin
                // Reset state has highest priority
                state <= HEADER;
                byte_count <= 10'd0;
                computed_checksum <= 16'd0;
                checksum_ok_reg <= 1'b0;
                checksum_valid_reg <= 1'b0;
            end else if (packet_end_reg && state != CHECKSUM_H) begin
                // Early termination has second priority
                state <= IDLE;
                checksum_valid_reg <= 1'b0;
            end else if (data_valid_reg) begin
                // Normal processing has lowest priority
                case (state)
                    HEADER: begin
                        byte_count <= byte_count + 1'b1;
                        if (is_header_complete) begin
                            state <= DATA;
                            byte_count <= 10'd0;
                        end
                    end
                    
                    DATA: begin
                        // Accumulate checksum
                        computed_checksum <= computed_checksum + rx_byte_reg;
                        
                        // Check for end of data
                        if (packet_end_reg) begin
                            state <= CHECKSUM_L;
                        end
                    end
                    
                    CHECKSUM_L: begin
                        checksum[7:0] <= rx_byte_reg;
                        state <= CHECKSUM_H;
                    end
                    
                    CHECKSUM_H: begin
                        checksum[15:8] <= rx_byte_reg;
                        checksum_valid_reg <= 1'b1;
                        // Direct equality comparison for better timing
                        checksum_ok_reg <= (computed_checksum == reconstructed_checksum);
                        state <= IDLE;
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule