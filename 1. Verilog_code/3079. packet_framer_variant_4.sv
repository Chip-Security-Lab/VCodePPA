//SystemVerilog
module packet_framer(
    // Global signals
    input wire clk,
    input wire rst,
    
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
    input wire s_axil_rready,
    
    // Packet framer output signals
    output reg [7:0] data_out,
    output reg tx_valid,
    output reg packet_done
);

    // Address mapping parameters
    localparam DATA_IN_ADDR    = 4'h0;  // Address 0x00
    localparam DATA_VALID_ADDR = 4'h1;  // Address 0x04
    localparam SOF_ADDR        = 4'h2;  // Address 0x08
    localparam EOF_ADDR        = 4'h3;  // Address 0x0C
    localparam STATUS_ADDR     = 4'h4;  // Address 0x10

    // State definition
    localparam IDLE=3'd0, HEADER=3'd1, PAYLOAD=3'd2, 
               CRC=3'd3, TRAILER=3'd4, DONE=3'd5;
               
    // Internal signals
    reg [2:0] state, next;
    reg [7:0] frame_header;
    reg [7:0] byte_count;
    reg [15:0] crc;
    
    // Register to store input signals
    reg [7:0] data_in;
    reg data_valid;
    reg sof, eof;
    
    // Status register
    reg [31:0] status_reg;
    
    // AXI4-Lite write registers
    reg write_address_valid;
    reg [31:0] write_address;
    reg write_data_valid;
    reg [31:0] write_data;
    reg [3:0] write_strobe;
    
    // AXI4-Lite read registers
    reg read_address_valid;
    reg [31:0] read_address;
    
    // Write address channel handling
    always @(posedge clk) begin
        if (rst) begin
            s_axil_awready <= 1'b1;
            write_address_valid <= 1'b0;
            write_address <= 32'b0;
        end else if (s_axil_awvalid && s_axil_awready) begin
            write_address <= s_axil_awaddr;
            write_address_valid <= 1'b1;
            s_axil_awready <= 1'b0;
        end else if (write_data_valid && write_address_valid) begin
            write_address_valid <= 1'b0;
            s_axil_awready <= 1'b1;
        end
    end
    
    // Write data channel handling
    always @(posedge clk) begin
        if (rst) begin
            s_axil_wready <= 1'b1;
            write_data_valid <= 1'b0;
            write_data <= 32'b0;
            write_strobe <= 4'b0;
        end else if (s_axil_wvalid && s_axil_wready) begin
            write_data <= s_axil_wdata;
            write_strobe <= s_axil_wstrb;
            write_data_valid <= 1'b1;
            s_axil_wready <= 1'b0;
        end else if (write_data_valid && write_address_valid) begin
            write_data_valid <= 1'b0;
            s_axil_wready <= 1'b1;
        end
    end
    
    // Write response channel handling
    always @(posedge clk) begin
        if (rst) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b0;
        end else if (write_data_valid && write_address_valid) begin
            s_axil_bvalid <= 1'b1;
            s_axil_bresp <= 2'b00; // OKAY response
        end else if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
        end
    end

    // Read address channel handling
    always @(posedge clk) begin
        if (rst) begin
            s_axil_arready <= 1'b1;
            read_address_valid <= 1'b0;
            read_address <= 32'b0;
        end else if (s_axil_arvalid && s_axil_arready) begin
            read_address <= s_axil_araddr;
            read_address_valid <= 1'b1;
            s_axil_arready <= 1'b0;
        end else if (s_axil_rvalid && s_axil_rready) begin
            read_address_valid <= 1'b0;
            s_axil_arready <= 1'b1;
        end
    end
    
    // Read data channel handling
    always @(posedge clk) begin
        if (rst) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b0;
            s_axil_rdata <= 32'b0;
        end else if (read_address_valid && !s_axil_rvalid) begin
            s_axil_rvalid <= 1'b1;
            s_axil_rresp <= 2'b00; // OKAY response
            
            case (read_address[5:2])
                STATUS_ADDR: s_axil_rdata <= status_reg;
                default: s_axil_rdata <= 32'b0;
            endcase
        end else if (s_axil_rvalid && s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end
    
    // Write handling logic - decoding AXI4-Lite writes
    always @(posedge clk) begin
        if (rst) begin
            data_in <= 8'b0;
            data_valid <= 1'b0;
            sof <= 1'b0;
            eof <= 1'b0;
        end else if (write_data_valid && write_address_valid) begin
            case (write_address[5:2])
                DATA_IN_ADDR: begin
                    if (write_strobe[0]) data_in <= write_data[7:0];
                end
                DATA_VALID_ADDR: begin
                    if (write_strobe[0]) data_valid <= write_data[0];
                end
                SOF_ADDR: begin
                    if (write_strobe[0]) sof <= write_data[0];
                end
                EOF_ADDR: begin
                    if (write_strobe[0]) eof <= write_data[0];
                end
                default: begin
                    // No operation for unrecognized addresses
                end
            endcase
        end else begin
            // Auto-clear control signals after one cycle
            data_valid <= 1'b0;
            sof <= 1'b0;
            eof <= 1'b0;
        end
    end
    
    // Status register update
    always @(posedge clk) begin
        if (rst) begin
            status_reg <= 32'b0;
        end else begin
            status_reg <= {
                16'b0,              // Reserved
                crc,                // Current CRC value
                5'b0,               // Reserved
                state,              // Current state
                tx_valid,           // TX valid flag
                packet_done         // Packet done flag
            };
        end
    end
    
    // Original packet framer state machine logic
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            frame_header <= 8'hA5; // Fixed frame header
            byte_count <= 8'd0;
            crc <= 16'd0;
            tx_valid <= 1'b0;
            packet_done <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    tx_valid <= 1'b0;
                    packet_done <= 1'b0;
                    byte_count <= 8'd0;
                    crc <= 16'd0;
                end
                HEADER: begin
                    data_out <= frame_header;
                    tx_valid <= 1'b1;
                end
                PAYLOAD: begin
                    if (data_valid) begin
                        data_out <= data_in;
                        tx_valid <= 1'b1;
                        byte_count <= byte_count + 8'd1;
                        // Simple CRC calculation
                        crc <= crc ^ {8'd0, data_in};
                    end else
                        tx_valid <= 1'b0;
                end
                CRC: begin
                    case (byte_count[0])
                        1'b0: begin data_out <= crc[7:0]; tx_valid <= 1'b1; end
                        1'b1: begin data_out <= crc[15:8]; tx_valid <= 1'b1; end
                    endcase
                    byte_count <= byte_count + 8'd1;
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
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE:    next = sof ? HEADER : IDLE;
            HEADER:  next = PAYLOAD;
            PAYLOAD: next = eof ? CRC : PAYLOAD;
            CRC:     next = (byte_count[0]) ? TRAILER : CRC;
            TRAILER: next = DONE;
            DONE:    next = IDLE;
            default: next = IDLE;
        endcase
    end

endmodule