//SystemVerilog
//IEEE 1364-2005 Verilog
module bidir_demux_axi4lite (
    // AXI4-Lite Interface
    input wire aclk,                     // Clock
    input wire aresetn,                  // Reset, active low
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,      // Write address
    input wire [2:0] s_axi_awprot,       // Write protection type
    input wire s_axi_awvalid,            // Write address valid
    output reg s_axi_awready,            // Write address ready
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,       // Write data
    input wire [3:0] s_axi_wstrb,        // Write strobe
    input wire s_axi_wvalid,             // Write valid
    output reg s_axi_wready,             // Write ready
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,        // Write response
    output reg s_axi_bvalid,             // Write response valid
    input wire s_axi_bready,             // Write response ready
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,      // Read address
    input wire [2:0] s_axi_arprot,       // Read protection type
    input wire s_axi_arvalid,            // Read address valid
    output reg s_axi_arready,            // Read address ready
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,       // Read data
    output reg [1:0] s_axi_rresp,        // Read response
    output reg s_axi_rvalid,             // Read valid
    input wire s_axi_rready,             // Read ready
    
    // Bidirectional signals
    inout wire common_io,                // Bidirectional common port
    inout wire [3:0] channel_io          // Bidirectional channel ports
);

    // Internal registers for control
    reg [1:0] channel_sel_reg;           // Channel selection register
    reg direction_reg;                   // Direction control register
    
    // Decoder signal
    wire [3:0] channel_enable;
    
    // Direction control signals
    wire common_to_channel = !direction_reg;
    wire channel_to_common = direction_reg;
    
    // Address decoding parameters - register map
    localparam ADDR_CTRL_REG     = 8'h00; // Control register (bit 0: direction, bits 2:1: channel_sel)
    localparam ADDR_STATUS_REG   = 8'h04; // Status register
    localparam ADDR_IO_DATA      = 8'h08; // IO data register
    
    // AXI4-Lite write transaction FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    // AXI4-Lite read transaction FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    // FSM state registers
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    // Address registers
    reg [7:0] write_addr, read_addr;
    
    // IO status register
    reg [31:0] status_reg;
    
    // Selected channel for reading
    reg selected_channel;
    
    // Response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERR  = 2'b10;
    
    // Decoder for channel selection
    assign channel_enable[0] = (channel_sel_reg == 2'b00) ? 1'b1 : 1'b0;
    assign channel_enable[1] = (channel_sel_reg == 2'b01) ? 1'b1 : 1'b0;
    assign channel_enable[2] = (channel_sel_reg == 2'b10) ? 1'b1 : 1'b0;
    assign channel_enable[3] = (channel_sel_reg == 2'b11) ? 1'b1 : 1'b0;
    
    // Channel outputs with explicit enable signals
    assign channel_io[0] = (common_to_channel && channel_enable[0]) ? common_io : 1'bz;
    assign channel_io[1] = (common_to_channel && channel_enable[1]) ? common_io : 1'bz;
    assign channel_io[2] = (common_to_channel && channel_enable[2]) ? common_io : 1'bz;
    assign channel_io[3] = (common_to_channel && channel_enable[3]) ? common_io : 1'bz;
    
    // 4-to-1 multiplexer
    always @(*) begin
        case (channel_sel_reg)
            2'b00: selected_channel = channel_io[0];
            2'b01: selected_channel = channel_io[1];
            2'b10: selected_channel = channel_io[2];
            2'b11: selected_channel = channel_io[3];
            default: selected_channel = 1'bz;
        endcase
    end
    
    // Output of mux to common port
    assign common_io = channel_to_common ? selected_channel : 1'bz;
    
    // Status register update
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            status_reg <= 32'h0;
        end else begin
            status_reg <= {27'b0, channel_io, common_io};
        end
    end
    
    //=========================================================================
    // Write transaction FSM
    //=========================================================================
    
    // Write state transition
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
        end else begin
            write_state <= write_next;
        end
    end
    
    // Write next state logic
    always @(*) begin
        write_next = write_state;
        
        case (write_state)
            WRITE_IDLE: 
                if (s_axi_awvalid) 
                    write_next = WRITE_DATA;
            
            WRITE_DATA: 
                if (s_axi_wvalid) 
                    write_next = WRITE_RESP;
            
            WRITE_RESP: 
                if (s_axi_bready) 
                    write_next = WRITE_IDLE;
            
            default: 
                write_next = WRITE_IDLE;
        endcase
    end
    
    // Write channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            write_addr <= 8'h0;
            channel_sel_reg <= 2'b00;
            direction_reg <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                    
                    if (s_axi_awvalid) begin
                        write_addr <= s_axi_awaddr[7:0];
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    s_axi_awready <= 1'b0;
                    
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= RESP_OKAY;
                        
                        // Process write data to appropriate register
                        case (write_addr)
                            ADDR_CTRL_REG: begin
                                direction_reg <= s_axi_wdata[0];
                                channel_sel_reg <= s_axi_wdata[2:1];
                            end
                            
                            default: begin
                                // Invalid address
                                s_axi_bresp <= RESP_ERR;
                            end
                        endcase
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                    end
                end
                
                default: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                end
            endcase
        end
    end
    
    //=========================================================================
    // Read transaction FSM
    //=========================================================================
    
    // Read state transition
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
        end else begin
            read_state <= read_next;
        end
    end
    
    // Read next state logic
    always @(*) begin
        read_next = read_state;
        
        case (read_state)
            READ_IDLE: 
                if (s_axi_arvalid) 
                    read_next = READ_DATA;
            
            READ_DATA: 
                if (s_axi_rready) 
                    read_next = READ_IDLE;
            
            default: 
                read_next = READ_IDLE;
        endcase
    end
    
    // Read channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
            read_addr <= 8'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                    
                    if (s_axi_arvalid) begin
                        read_addr <= s_axi_araddr[7:0];
                        s_axi_arready <= 1'b0;
                    end
                end
                
                READ_DATA: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= RESP_OKAY;
                    
                    // Select appropriate register for read
                    case (read_addr)
                        ADDR_CTRL_REG: begin
                            s_axi_rdata <= {29'b0, channel_sel_reg, direction_reg};
                        end
                        
                        ADDR_STATUS_REG: begin
                            s_axi_rdata <= status_reg;
                        end
                        
                        ADDR_IO_DATA: begin
                            s_axi_rdata <= {31'b0, selected_channel};
                        end
                        
                        default: begin
                            // Invalid address
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= RESP_ERR;
                        end
                    endcase
                    
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end
                
                default: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid <= 1'b0;
                end
            endcase
        end
    end

endmodule