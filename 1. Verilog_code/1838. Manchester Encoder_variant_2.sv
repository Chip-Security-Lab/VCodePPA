//SystemVerilog
module manchester_encoder (
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    
    // Write data channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    
    // Write response channel
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    
    // Read address channel
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    
    // Read data channel
    output reg [31:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,
    
    // Manchester encoder output
    output reg          manchester_out
);

    // Internal registers
    reg data_in_reg;
    reg polarity_reg;
    reg clk_div2;
    
    // Register addresses (byte-addressed)
    localparam ADDR_CONTROL_REG = 4'h0;     // Control register at offset 0
    localparam ADDR_STATUS_REG  = 4'h4;     // Status register at offset 4
    
    // AXI4-Lite write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // AXI4-Lite read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // FSM registers
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    // Address registers
    reg [3:0] write_addr, read_addr;
    
    // Write channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            write_state <= WRITE_IDLE;
        else
            write_state <= write_next;
    end
    
    always @(*) begin
        write_next = write_state;
        
        case (write_state)
            WRITE_IDLE: begin
                if (s_axi_awvalid)
                    write_next = WRITE_ADDR;
            end
            
            WRITE_ADDR: begin
                if (s_axi_wvalid)
                    write_next = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                write_next = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (s_axi_bready)
                    write_next = WRITE_IDLE;
            end
        endcase
    end
    
    // Write channel control signals
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;  // OKAY response
            write_addr <= 4'h0;
            
            // Initialize control registers
            data_in_reg <= 1'b0;
            polarity_reg <= 1'b0;
        end
        else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                end
                
                WRITE_ADDR: begin
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr <= s_axi_awaddr[3:0];  // Capture the write address
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        
                        // Handle register writes
                        if (write_addr == ADDR_CONTROL_REG && s_axi_wstrb[0]) begin
                            data_in_reg <= s_axi_wdata[0];    // Bit 0: data_in
                            polarity_reg <= s_axi_wdata[1];   // Bit 1: polarity
                        end
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready && s_axi_bvalid)
                        s_axi_bvalid <= 1'b0;
                end
            endcase
        end
    end
    
    // Read channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            read_state <= READ_IDLE;
        else
            read_state <= read_next;
    end
    
    always @(*) begin
        read_next = read_state;
        
        case (read_state)
            READ_IDLE: begin
                if (s_axi_arvalid)
                    read_next = READ_ADDR;
            end
            
            READ_ADDR: begin
                read_next = READ_DATA;
            end
            
            READ_DATA: begin
                if (s_axi_rready)
                    read_next = READ_IDLE;
            end
        endcase
    end
    
    // Read channel control signals
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;  // OKAY response
            read_addr <= 4'h0;
        end
        else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                end
                
                READ_ADDR: begin
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr <= s_axi_araddr[3:0];  // Capture the read address
                        s_axi_arready <= 1'b0;
                    end
                end
                
                READ_DATA: begin
                    s_axi_rvalid <= 1'b1;
                    
                    // Handle register reads
                    case (read_addr)
                        ADDR_CONTROL_REG: begin
                            s_axi_rdata <= {30'h0, polarity_reg, data_in_reg};
                        end
                        
                        ADDR_STATUS_REG: begin
                            s_axi_rdata <= {31'h0, manchester_out};
                        end
                        
                        default: begin
                            s_axi_rdata <= 32'h0;
                        end
                    endcase
                    
                    if (s_axi_rready && s_axi_rvalid)
                        s_axi_rvalid <= 1'b0;
                end
            endcase
        end
    end
    
    // Manchester encoder logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            clk_div2 <= 1'b0;
            manchester_out <= 1'b0;
        end
        else begin
            clk_div2 <= ~clk_div2;
            manchester_out <= polarity_reg ? (data_in_reg ^ ~clk_div2) : (data_in_reg ^ clk_div2);
        end
    end

endmodule