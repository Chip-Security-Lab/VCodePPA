//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Standard
module fsm_display_codec (
    // Clock and reset
    input                   s_axi_aclk,
    input                   s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  [7:0]            s_axi_awaddr,
    input                   s_axi_awvalid,
    output reg              s_axi_awready,
    
    // AXI4-Lite write data channel
    input  [31:0]           s_axi_wdata,
    input  [3:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output reg              s_axi_wready,
    
    // AXI4-Lite write response channel
    output reg [1:0]        s_axi_bresp,
    output reg              s_axi_bvalid,
    input                   s_axi_bready,
    
    // AXI4-Lite read address channel
    input  [7:0]            s_axi_araddr,
    input                   s_axi_arvalid,
    output reg              s_axi_arready,
    
    // AXI4-Lite read data channel
    output reg [31:0]       s_axi_rdata,
    output reg [1:0]        s_axi_rresp,
    output reg              s_axi_rvalid,
    input                   s_axi_rready
);

    // Register map
    localparam REG_PIXEL_IN_LOW     = 8'h00;  // [15:0] of pixel_in
    localparam REG_PIXEL_IN_HIGH    = 8'h04;  // [23:16] of pixel_in
    localparam REG_CONTROL          = 8'h08;  // bit 0: start_conversion
    localparam REG_STATUS           = 8'h0C;  // bit 0: busy, bit 1: done
    localparam REG_PIXEL_OUT        = 8'h10;  // [15:0] pixel_out
    
    // FSM states - one-hot encoding for better timing
    localparam IDLE = 3'b001;
    localparam PROCESS = 3'b010;
    localparam OUTPUT = 3'b100;
    
    // Internal registers
    reg [2:0] state, next_state;
    reg [23:0] pixel_in;
    reg start_conversion;
    reg [15:0] pixel_out;
    reg busy, done;
    
    // Pre-compute RGB conversion with direct bit selection
    wire [15:0] rgb565_data = {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
    reg [15:0] processed_data;
    
    // AXI write transaction handling
    reg axi_write_ready;
    reg [7:0] write_addr;
    
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            axi_write_ready <= 1'b0;
            write_addr <= 8'h00;
            
            // Reset core registers
            pixel_in <= 24'h000000;
            start_conversion <= 1'b0;
        end else begin
            // Handle write address channel
            if (s_axi_awvalid && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                write_addr <= s_axi_awaddr;
            end else if (s_axi_awready) begin
                s_axi_awready <= 1'b0;
            end
            
            // Handle write data channel
            if (s_axi_wvalid && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
                axi_write_ready <= 1'b1;
            end else if (s_axi_wready) begin
                s_axi_wready <= 1'b0;
            end
            
            // Process write data when both address and data are ready
            if (axi_write_ready) begin
                axi_write_ready <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
                
                case (write_addr)
                    REG_PIXEL_IN_LOW: begin
                        if (s_axi_wstrb[0]) pixel_in[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) pixel_in[15:8] <= s_axi_wdata[15:8];
                    end
                    REG_PIXEL_IN_HIGH: begin
                        if (s_axi_wstrb[0]) pixel_in[23:16] <= s_axi_wdata[7:0];
                    end
                    REG_CONTROL: begin
                        if (s_axi_wstrb[0]) start_conversion <= s_axi_wdata[0];
                    end
                    default: begin
                        // No operation for unmapped registers
                    end
                endcase
            end
            
            // Complete write transaction
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
            
            // Auto-clear start_conversion after being set
            if (start_conversion && state == IDLE && next_state == PROCESS) begin
                start_conversion <= 1'b0;
            end
        end
    end
    
    // AXI read transaction handling
    reg [7:0] read_addr;
    
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h00000000;
            read_addr <= 8'h00;
        end else begin
            // Handle read address channel
            if (s_axi_arvalid && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
                read_addr <= s_axi_araddr;
            end else if (s_axi_arready) begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                
                // Set read data based on address
                case (read_addr)
                    REG_PIXEL_IN_LOW:  s_axi_rdata <= {16'h0000, pixel_in[15:0]};
                    REG_PIXEL_IN_HIGH: s_axi_rdata <= {24'h000000, pixel_in[23:16]};
                    REG_CONTROL:       s_axi_rdata <= {31'h00000000, start_conversion};
                    REG_STATUS:        s_axi_rdata <= {30'h00000000, done, busy};
                    REG_PIXEL_OUT:     s_axi_rdata <= {16'h0000, pixel_out};
                    default:           s_axi_rdata <= 32'h00000000;
                endcase
            end
            
            // Complete read transaction
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // State register with synchronous reset
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Optimized next state logic using state bits directly for comparison
    always @(*) begin
        // Default assignment to prevent latches
        next_state = IDLE;
        
        if (state[0]) // IDLE
            next_state = start_conversion ? PROCESS : IDLE;
        else if (state[1]) // PROCESS
            next_state = OUTPUT;
        else if (state[2]) // OUTPUT
            next_state = IDLE;
    end
    
    // Optimized control signals using state bits directly
    wire is_process = state[1];
    wire is_output = state[2];
    
    // Data processing and output stage
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            pixel_out <= 16'h0000;
            busy <= 1'b0;
            done <= 1'b0;
            processed_data <= 16'h0000;
        end else begin
            // Optimized control signals using direct bit comparison
            busy <= is_process;
            done <= is_output;
            
            // Conditional assignments based on state
            if (is_process)
                processed_data <= rgb565_data;
                
            if (is_output)
                pixel_out <= processed_data;
        end
    end
endmodule