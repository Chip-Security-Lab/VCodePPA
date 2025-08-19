//SystemVerilog
module serial_display_codec (
    input wire clk,                     // Clock
    input wire rst_n,                   // Reset, active low
    
    // AXI4-Lite Interface
    // Write Address Channel
    input wire [7:0] s_axil_awaddr,     // Write address
    input wire s_axil_awvalid,          // Write address valid
    output reg s_axil_awready,          // Write address ready
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,     // Write data
    input wire [3:0] s_axil_wstrb,      // Write strobe
    input wire s_axil_wvalid,           // Write valid
    output reg s_axil_wready,           // Write ready
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,      // Write response
    output reg s_axil_bvalid,           // Write response valid
    input wire s_axil_bready,           // Write response ready
    
    // Read Address Channel
    input wire [7:0] s_axil_araddr,     // Read address
    input wire s_axil_arvalid,          // Read address valid
    output reg s_axil_arready,          // Read address ready
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,     // Read data
    output reg [1:0] s_axil_rresp,      // Read response
    output reg s_axil_rvalid,           // Read valid
    input wire s_axil_rready,           // Read ready
    
    // Serial Interface Outputs
    output reg serial_data,             // Serial data output
    output reg serial_clk,              // Serial clock output
    output wire tx_active,              // Transmission active
    output wire tx_done                 // Transmission done
);

    // Register map
    localparam REG_CTRL      = 8'h00;   // Control register (bit 0: start_tx)
    localparam REG_STATUS    = 8'h04;   // Status register (bit 0: tx_done, bit 1: tx_active)
    localparam REG_RGB_DATA  = 8'h08;   // RGB data register (24-bit RGB data)
    
    // Internal registers
    reg [23:0] rgb_in;                  // RGB data storage
    reg start_tx;                       // Transmission start signal
    reg [4:0] bit_counter;              // Bit counter for serial transmission
    reg [15:0] shift_reg;               // Shift register
    reg tx_active_reg;                  // Transmission active register
    reg tx_done_reg;                    // Transmission done register
    
    // Read and write control registers
    reg [7:0] read_addr;                // Registered read address
    reg read_req_pending;               // Read request pending
    reg write_req_pending;              // Write request pending
    reg [7:0] write_addr;               // Registered write address
    reg [31:0] write_data;              // Registered write data
    reg [3:0] write_strb;               // Registered write strobe
    
    // Optimized AXI-Lite FSM states
    localparam IDLE = 2'b00;
    localparam ADDR_PHASE = 2'b01;
    localparam DATA_PHASE = 2'b10;
    localparam RESP_PHASE = 2'b11;
    
    reg [1:0] write_state, read_state;
    
    // AXI4-Lite Write Channel FSM - optimized implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_req_pending <= 1'b0;
            write_addr <= 8'h0;
            write_data <= 32'h0;
            write_strb <= 4'h0;
            write_state <= IDLE;
        end else begin
            // Default values to avoid latches
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            
            case (write_state)
                IDLE: begin
                    // Check for address write request
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                        write_addr <= s_axil_awaddr;
                        write_state <= ADDR_PHASE;
                    end else if (write_req_pending && s_axil_wvalid) begin
                        // Handle pending write request
                        s_axil_wready <= 1'b1;
                        write_data <= s_axil_wdata;
                        write_strb <= s_axil_wstrb;
                        write_req_pending <= 1'b0;
                        write_state <= DATA_PHASE;
                    end
                end
                
                ADDR_PHASE: begin
                    // Check for data write request
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                        write_data <= s_axil_wdata;
                        write_strb <= s_axil_wstrb;
                        write_state <= DATA_PHASE;
                    end else begin
                        write_req_pending <= 1'b1;
                        write_state <= IDLE;
                    end
                end
                
                DATA_PHASE: begin
                    // Move to response phase
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp <= 2'b00; // OKAY response
                    write_state <= RESP_PHASE;
                end
                
                RESP_PHASE: begin
                    // Wait for response acknowledgment
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end
    
    // AXI4-Lite Read Channel FSM - optimized implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
            read_req_pending <= 1'b0;
            read_addr <= 8'h0;
            read_state <= IDLE;
        end else begin
            // Default values to avoid latches
            s_axil_arready <= 1'b0;
            
            case (read_state)
                IDLE: begin
                    // Check for address read request
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        read_addr <= s_axil_araddr;
                        read_state <= ADDR_PHASE;
                    end
                end
                
                ADDR_PHASE: begin
                    // Prepare read data based on address
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // Default to OKAY
                    
                    // Address decode for read
                    if ((read_addr & 8'hFC) == REG_CTRL) begin
                        s_axil_rdata <= {31'b0, start_tx};
                    end else if ((read_addr & 8'hFC) == REG_STATUS) begin
                        s_axil_rdata <= {30'b0, tx_active_reg, tx_done_reg};
                    end else if ((read_addr & 8'hFC) == REG_RGB_DATA) begin
                        s_axil_rdata <= {8'b0, rgb_in};
                    end else begin
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= 2'b10; // SLVERR for invalid address
                    end
                    
                    read_state <= DATA_PHASE;
                end
                
                DATA_PHASE: begin
                    // Wait for read data acknowledgment
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end
    
    // Optimized register write handling with byte-enables
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_in <= 24'h0;
            start_tx <= 1'b0;
        end else begin
            // Auto-clear start_tx when transmission starts
            if (start_tx && tx_active_reg) begin
                start_tx <= 1'b0;
            end
            
            // Process write requests when data is valid and ready
            if (s_axil_wvalid && s_axil_wready) begin
                // Extract write address for decode
                reg [7:0] aligned_addr;
                aligned_addr = write_addr & 8'hFC; // Mask off lower bits for word alignment
                
                // Process control register write
                if (aligned_addr == REG_CTRL) begin
                    if (write_strb[0]) begin
                        start_tx <= s_axil_wdata[0];
                    end
                end 
                // Process RGB data register write with byte enables
                else if (aligned_addr == REG_RGB_DATA) begin
                    if (write_strb[0]) begin
                        rgb_in[7:0] <= s_axil_wdata[7:0];
                    end
                    
                    if (write_strb[1]) begin
                        rgb_in[15:8] <= s_axil_wdata[15:8];
                    end
                    
                    if (write_strb[2]) begin
                        rgb_in[23:16] <= s_axil_wdata[23:16];
                    end
                end
                // No action for unmapped addresses
            end
        end
    end
    
    // Optimized serial transmission logic with state-based control
    localparam TX_IDLE      = 2'b00;
    localparam TX_SETUP     = 2'b01;
    localparam TX_DATA      = 2'b10;
    localparam TX_COMPLETE  = 2'b11;
    
    reg [1:0] tx_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
            serial_data <= 1'b0;
            serial_clk <= 1'b0;
            tx_active_reg <= 1'b0;
            tx_done_reg <= 1'b0;
            tx_state <= TX_IDLE;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    // Check if transmission should start
                    reg start_condition;
                    start_condition = start_tx && !tx_active_reg && !tx_done_reg;
                    
                    if (start_condition) begin
                        // RGB888 to RGB565 conversion
                        reg [4:0] red_part, blue_part;
                        reg [5:0] green_part;
                        
                        red_part = rgb_in[23:19];
                        green_part = rgb_in[15:10];
                        blue_part = rgb_in[7:3];
                        
                        // Load shift register with RGB565 data
                        shift_reg <= {red_part, green_part, blue_part};
                        
                        // Initialize other signals
                        bit_counter <= 5'd0;
                        tx_active_reg <= 1'b1;
                        tx_done_reg <= 1'b0;
                        tx_state <= TX_SETUP;
                    end else if (tx_done_reg && !start_tx) begin
                        // Clear done flag when start is deasserted
                        tx_done_reg <= 1'b0;
                    end
                end
                
                TX_SETUP: begin
                    // Prepare for data transmission
                    serial_clk <= 1'b0;
                    serial_data <= shift_reg[15];
                    tx_state <= TX_DATA;
                end
                
                TX_DATA: begin
                    // Toggle clock for serial transmission
                    serial_clk <= ~serial_clk;
                    
                    // On falling edge of serial clock
                    if (serial_clk) begin
                        // Update data bit and shift register
                        serial_data <= shift_reg[15];
                        shift_reg <= {shift_reg[14:0], 1'b0};
                        
                        // Check if all bits are transmitted
                        if (bit_counter == 5'd15) begin
                            tx_state <= TX_COMPLETE;
                        end else begin
                            bit_counter <= bit_counter + 5'd1;
                        end
                    end
                end
                
                TX_COMPLETE: begin
                    // Clean up after transmission
                    serial_clk <= 1'b0;
                    tx_active_reg <= 1'b0;
                    tx_done_reg <= 1'b1;
                    tx_state <= TX_IDLE;
                end
                
                default: begin
                    tx_state <= TX_IDLE;
                end
            endcase
        end
    end
    
    // Connect internal status signals to outputs
    assign tx_active = tx_active_reg;
    assign tx_done = tx_done_reg;

endmodule