//SystemVerilog
module piso_reg_axi4lite (
    // Global signals
    input wire aclk,                   
    input wire aresetn,                
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axil_awaddr,   
    input wire [2:0] s_axil_awprot,    
    input wire s_axil_awvalid,         
    output reg s_axil_awready,         
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axil_wdata,    
    input wire [3:0] s_axil_wstrb,     
    input wire s_axil_wvalid,          
    output reg s_axil_wready,          
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axil_bresp,     
    output reg s_axil_bvalid,          
    input wire s_axil_bready,          
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,   
    input wire [2:0] s_axil_arprot,    
    input wire s_axil_arvalid,         
    output reg s_axil_arready,         
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axil_rdata,    
    output reg [1:0] s_axil_rresp,     
    output reg s_axil_rvalid,          
    input wire s_axil_rready,          
    
    // Original output
    output wire serial_out             
);

    // Register address mapping
    localparam REG_DATA_ADDR     = 4'h0;  // Address offset for data register
    localparam REG_CONTROL_ADDR  = 4'h4;  // Address offset for control register
    
    // Register values
    reg [7:0] data_reg = 8'h00;          // PISO shift register
    reg load_reg = 1'b0;                 // Load control bit
    reg clear_reg = 1'b1;                // Clear control bit (active low)
    
    // AXI4-Lite FSM states
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] write_state = IDLE;
    reg [1:0] read_state = IDLE;
    reg [3:0] addr_latch;
    
    // Pre-registered inputs to improve timing
    reg [31:0] s_axil_awaddr_reg;
    reg s_axil_awvalid_reg;
    reg [31:0] s_axil_wdata_reg;
    reg s_axil_wvalid_reg;
    reg s_axil_bready_reg;
    reg [31:0] s_axil_araddr_reg;
    reg s_axil_arvalid_reg;
    reg s_axil_rready_reg;
    
    // Register input signals to reduce input timing paths
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_awaddr_reg <= 32'h0;
            s_axil_awvalid_reg <= 1'b0;
            s_axil_wdata_reg <= 32'h0;
            s_axil_wvalid_reg <= 1'b0;
            s_axil_bready_reg <= 1'b0;
            s_axil_araddr_reg <= 32'h0;
            s_axil_arvalid_reg <= 1'b0;
            s_axil_rready_reg <= 1'b0;
        end
        else begin
            s_axil_awaddr_reg <= s_axil_awaddr;
            s_axil_awvalid_reg <= s_axil_awvalid;
            s_axil_wdata_reg <= s_axil_wdata;
            s_axil_wvalid_reg <= s_axil_wvalid;
            s_axil_bready_reg <= s_axil_bready;
            s_axil_araddr_reg <= s_axil_araddr;
            s_axil_arvalid_reg <= s_axil_arvalid;
            s_axil_rready_reg <= s_axil_rready;
        end
    end
    
    // Core PISO shift register logic - moved after input registration
    always @(posedge aclk) begin
        if (!aresetn || !clear_reg) begin
            data_reg <= 8'h00;
        end
        else if (load_reg) begin
            data_reg <= s_axil_wdata_reg[7:0];  // Load parallel data from registered AXI write data
        end
        else begin
            data_reg <= {data_reg[6:0], 1'b0};  // Shift left
        end
    end
    
    // AXI4-Lite Write Transaction
    always @(posedge aclk) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            load_reg <= 1'b0;
            clear_reg <= 1'b1;
        end
        else begin
            // Default control signal values
            load_reg <= 1'b0;  // Load is pulse-based, so reset by default
            
            case (write_state)
                IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b1;
                    if (s_axil_awvalid_reg && s_axil_awready) begin
                        addr_latch <= s_axil_awaddr_reg[3:0];  // Latch registered write address
                        s_axil_awready <= 1'b0;
                        if (s_axil_wvalid_reg) begin
                            // Address and data arrived together
                            write_state <= RESP;
                            s_axil_wready <= 1'b0;
                            
                            // Process the write based on address
                            if (s_axil_awaddr_reg[3:0] == REG_DATA_ADDR) begin
                                load_reg <= 1'b1;  // Trigger load operation
                            end
                            else if (s_axil_awaddr_reg[3:0] == REG_CONTROL_ADDR) begin
                                clear_reg <= s_axil_wdata_reg[0];  // Set clear bit
                            end
                            
                            s_axil_bvalid <= 1'b1;
                            s_axil_bresp <= 2'b00;  // OKAY response
                        end
                        else begin
                            write_state <= ADDR;
                        end
                    end
                    else if (s_axil_wvalid_reg && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        write_state <= DATA;
                    end
                end
                
                ADDR: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid_reg) begin
                        s_axil_wready <= 1'b0;
                        
                        // Process the write based on latched address
                        if (addr_latch == REG_DATA_ADDR) begin
                            load_reg <= 1'b1;  // Trigger load operation
                        end
                        else if (addr_latch == REG_CONTROL_ADDR) begin
                            clear_reg <= s_axil_wdata_reg[0];  // Set clear bit
                        end
                        
                        write_state <= RESP;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00;  // OKAY response
                    end
                end
                
                DATA: begin
                    s_axil_awready <= 1'b1;
                    if (s_axil_awvalid_reg) begin
                        s_axil_awready <= 1'b0;
                        addr_latch <= s_axil_awaddr_reg[3:0];
                        
                        // Process the write based on address
                        if (s_axil_awaddr_reg[3:0] == REG_DATA_ADDR) begin
                            load_reg <= 1'b1;  // Trigger load operation
                        end
                        else if (s_axil_awaddr_reg[3:0] == REG_CONTROL_ADDR) begin
                            clear_reg <= s_axil_wdata_reg[0];  // Set clear bit
                        end
                        
                        write_state <= RESP;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00;  // OKAY response
                    end
                end
                
                RESP: begin
                    if (s_axil_bready_reg && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= IDLE;
                        s_axil_awready <= 1'b1;
                        s_axil_wready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // AXI4-Lite Read Transaction
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
        end
        else begin
            case (read_state)
                IDLE: begin
                    s_axil_arready <= 1'b1;
                    if (s_axil_arvalid_reg && s_axil_arready) begin
                        s_axil_arready <= 1'b0;
                        read_state <= RESP;
                        
                        // Prepare read data based on address
                        if (s_axil_araddr_reg[3:0] == REG_DATA_ADDR) begin
                            s_axil_rdata <= {24'h0, data_reg};  // Return current shift register value
                        end
                        else if (s_axil_araddr_reg[3:0] == REG_CONTROL_ADDR) begin
                            s_axil_rdata <= {30'h0, load_reg, clear_reg};  // Return control bits
                        end
                        else begin
                            s_axil_rdata <= 32'h0;  // Return 0 for invalid addresses
                        end
                        
                        s_axil_rvalid <= 1'b1;
                        s_axil_rresp <= 2'b00;  // OKAY response
                    end
                end
                
                RESP: begin
                    if (s_axil_rready_reg && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                        s_axil_arready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // Pre-registered output for better timing
    reg serial_out_reg;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            serial_out_reg <= 1'b0;
        end
        else begin
            serial_out_reg <= data_reg[7];
        end
    end
    
    // Connect the serial output to the registered MSB of the shift register
    assign serial_out = serial_out_reg;
    
endmodule