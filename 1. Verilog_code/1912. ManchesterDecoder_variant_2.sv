//SystemVerilog - IEEE 1364-2005
module ManchesterDecoder (
    // Global signals
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel (Req-Ack)
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awreq,
    output reg s_axi_awack,
    
    // AXI4-Lite Write Data Channel (Req-Ack)
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wreq,
    output reg s_axi_wack,
    
    // AXI4-Lite Write Response Channel (Req-Ack)
    output reg [1:0] s_axi_bresp,
    output reg s_axi_breq,
    input wire s_axi_back,
    
    // AXI4-Lite Read Address Channel (Req-Ack)
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arreq,
    output reg s_axi_arack,
    
    // AXI4-Lite Read Data Channel (Req-Ack)
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rreq,
    input wire s_axi_rack,
    
    // Original manchester input signal
    input wire manchester_in
);

    // Memory mapped registers
    reg [7:0] decoded_data;
    reg valid;
    
    // Original logic signals
    reg [3:0] bit_counter;
    reg [15:0] shift_reg;
    
    // Register addresses (word-aligned for 32-bit AXI)
    localparam ADDR_STATUS     = 4'h0;  // Status register (bit 0: valid flag)
    localparam ADDR_DATA       = 4'h4;  // Decoded data register
    localparam ADDR_CONTROL    = 4'h8;  // Control register (future use)
    
    // AXI FSM states
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // AXI state registers
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // Address registers
    reg [31:0] axi_awaddr_reg;
    reg [31:0] axi_araddr_reg;
    
    // Response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    //==========================================
    // Manchester Decoder Core Logic - Shift Register
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            shift_reg <= 16'h0000;
        end else begin
            shift_reg <= {shift_reg[14:0], manchester_in};
        end
    end

    //==========================================
    // Manchester Decoder Core Logic - Data Decoding
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            decoded_data <= 8'h00;
            valid <= 1'b0;
        end else begin
            if (shift_reg[15:8] == 8'b01010101) begin
                decoded_data <= shift_reg[7:0];
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

    //==========================================
    // Manchester Decoder Core Logic - Bit Counter
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            bit_counter <= 4'h0;
        end else begin
            if (shift_reg[15:8] == 8'b01010101) begin
                bit_counter <= 4'h0;
            end else begin
                bit_counter <= (bit_counter == 4'hF) ? 4'h0 : bit_counter + 4'h1;
            end
        end
    end
    
    //==========================================
    // AXI4-Lite Write Channel - Address Phase (Req-Ack)
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_state <= IDLE;
            s_axi_awack <= 1'b0;
            axi_awaddr_reg <= 32'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axi_awreq && !s_axi_awack) begin
                        s_axi_awack <= 1'b1;
                        axi_awaddr_reg <= s_axi_awaddr;
                        write_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    if (s_axi_awreq && s_axi_awack) begin
                        if (s_axi_wreq) begin
                            s_axi_awack <= 1'b0;
                            write_state <= DATA;
                        end
                    end else begin
                        s_axi_awack <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                DATA: begin
                    if (s_axi_back && s_axi_breq) begin
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end

    //==========================================
    // AXI4-Lite Write Channel - Data Phase (Req-Ack)
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wack <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
        end else begin
            if (write_state == ADDR && s_axi_wreq && !s_axi_wack) begin
                s_axi_wack <= 1'b1;
                
                // Handle write data based on address
                case (axi_awaddr_reg[7:0])
                    ADDR_CONTROL: begin
                        // Control register writes - for future expansion
                        s_axi_bresp <= RESP_OKAY;
                    end
                    
                    default: begin
                        // Read-only or undefined registers
                        s_axi_bresp <= RESP_SLVERR;
                    end
                endcase
            end else if (s_axi_wack && !s_axi_wreq) begin
                s_axi_wack <= 1'b0;
            end
        end
    end

    //==========================================
    // AXI4-Lite Write Channel - Response Phase (Req-Ack)
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_breq <= 1'b0;
        end else begin
            if (write_state == DATA && s_axi_wack && !s_axi_breq) begin
                s_axi_breq <= 1'b1;
            end else if (s_axi_breq && s_axi_back) begin
                s_axi_breq <= 1'b0;
            end
        end
    end
    
    //==========================================
    // AXI4-Lite Read Channel - Address Phase (Req-Ack)
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= IDLE;
            s_axi_arack <= 1'b0;
            axi_araddr_reg <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axi_arreq && !s_axi_arack) begin
                        s_axi_arack <= 1'b1;
                        axi_araddr_reg <= s_axi_araddr;
                        read_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    if (s_axi_arreq && s_axi_arack) begin
                        s_axi_arack <= 1'b0;
                        read_state <= DATA;
                    end else begin
                        s_axi_arack <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                DATA: begin
                    if (s_axi_rack && s_axi_rreq) begin
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end

    //==========================================
    // AXI4-Lite Read Channel - Data Phase (Req-Ack)
    //==========================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rreq <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h00000000;
        end else begin
            if (read_state == ADDR && !s_axi_rreq) begin
                s_axi_rreq <= 1'b1;
                
                // Prepare read data based on address
                case (axi_araddr_reg[7:0])
                    ADDR_STATUS: begin
                        s_axi_rdata <= {31'b0, valid};
                        s_axi_rresp <= RESP_OKAY;
                    end
                    
                    ADDR_DATA: begin
                        s_axi_rdata <= {24'b0, decoded_data};
                        s_axi_rresp <= RESP_OKAY;
                    end
                    
                    default: begin
                        s_axi_rdata <= 32'h00000000;
                        s_axi_rresp <= RESP_SLVERR;
                    end
                endcase
            end else if (s_axi_rreq && s_axi_rack) begin
                s_axi_rreq <= 1'b0;
            end
        end
    end

endmodule