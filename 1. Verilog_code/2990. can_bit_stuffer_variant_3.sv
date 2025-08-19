//SystemVerilog
module can_bit_stuffer_axi4lite (
  // Clock and Reset
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
  
  // Status outputs
  output wire stuff_error
);

  // Register map
  // 0x00: Control Register [bit 0: data_in, bit 1: data_valid, bit 2: stuffing_active]
  // 0x04: Status Register [bit 0: data_out, bit 1: data_out_valid, bit 2: stuff_error]
  
  // Internal registers for bit stuffing logic
  reg [2:0] same_bit_count;
  reg last_bit;
  reg stuffed_bit;
  reg data_in, data_valid, stuffing_active;
  reg data_out, data_out_valid;
  reg stuff_error_reg;
  
  // Internal AXI state registers
  reg [31:0] control_reg;
  reg [31:0] status_reg;
  
  // Write address channel state machine
  localparam WRITE_IDLE = 1'b0;
  localparam WRITE_DATA = 1'b1;
  reg write_state;
  reg [31:0] write_addr;
  
  // Read address channel state machine
  localparam READ_IDLE = 1'b0;
  localparam READ_DATA = 1'b1;
  reg read_state;
  reg [31:0] read_addr;
  
  // AXI4-Lite write address channel
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_awready <= 1'b0;
      write_state <= WRITE_IDLE;
      write_addr <= 32'h0;
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          if (s_axil_awvalid) begin
            s_axil_awready <= 1'b1;
            write_addr <= s_axil_awaddr;
            write_state <= WRITE_DATA;
          end
        end
        WRITE_DATA: begin
          s_axil_awready <= 1'b0;
          if (s_axil_wvalid && s_axil_wready) begin
            write_state <= WRITE_IDLE;
          end
        end
      endcase
    end
  end
  
  // AXI4-Lite write data channel
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_wready <= 1'b0;
      s_axil_bvalid <= 1'b0;
      s_axil_bresp <= 2'b00;
      control_reg <= 32'h0;
    end else begin
      // Clear b valid when handshake completes
      if (s_axil_bvalid && s_axil_bready) begin
        s_axil_bvalid <= 1'b0;
      end
      
      // Handle write data
      if (write_state == WRITE_DATA) begin
        // Step 1: Set ready if not already
        if (s_axil_wvalid && !s_axil_wready) begin
          s_axil_wready <= 1'b1;
        end 
        // Step 2: Process write data when valid and ready
        else if (s_axil_wready && s_axil_wvalid) begin
          s_axil_wready <= 1'b0;
          s_axil_bvalid <= 1'b1;
          
          // Set default response
          s_axil_bresp <= 2'b00; // OKAY response
          
          // Process write based on address
          if (write_addr[3:0] == 4'h0) begin // Control register
            // Process each byte if strobe is set
            if (s_axil_wstrb[0]) begin
              control_reg[7:0] <= s_axil_wdata[7:0];
            end
            
            if (s_axil_wstrb[1]) begin
              control_reg[15:8] <= s_axil_wdata[15:8];
            end
            
            if (s_axil_wstrb[2]) begin
              control_reg[23:16] <= s_axil_wdata[23:16];
            end
            
            if (s_axil_wstrb[3]) begin
              control_reg[31:24] <= s_axil_wdata[31:24];
            end
          end else begin
            // Invalid address - return error response
            s_axil_bresp <= 2'b10; // SLVERR response
          end
        end
      end
    end
  end
  
  // AXI4-Lite read address channel
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_arready <= 1'b0;
      read_state <= READ_IDLE;
      read_addr <= 32'h0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          if (s_axil_arvalid) begin
            s_axil_arready <= 1'b1;
            read_addr <= s_axil_araddr;
            read_state <= READ_DATA;
          end
        end
        READ_DATA: begin
          s_axil_arready <= 1'b0;
          if (s_axil_rvalid && s_axil_rready) begin
            read_state <= READ_IDLE;
          end
        end
      endcase
    end
  end
  
  // AXI4-Lite read data channel
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_rvalid <= 1'b0;
      s_axil_rresp <= 2'b00;
      s_axil_rdata <= 32'h0;
    end else begin
      // Clear valid when handshake completes
      if (s_axil_rvalid && s_axil_rready) begin
        s_axil_rvalid <= 1'b0;
      end
      
      // Generate read response
      if (!s_axil_rvalid && read_state == READ_DATA) begin
        s_axil_rvalid <= 1'b1;
        
        // Default response
        s_axil_rresp <= 2'b00; // OKAY response
        
        // Address decoding
        if (read_addr[3:0] == 4'h0) begin 
          // Control register
          s_axil_rdata <= control_reg;
        end else if (read_addr[3:0] == 4'h4) begin 
          // Status register
          s_axil_rdata <= {29'h0, stuff_error_reg, data_out_valid, data_out};
        end else begin
          // Invalid address
          s_axil_rdata <= 32'h0;
          s_axil_rresp <= 2'b10; // SLVERR response
        end
      end
    end
  end
  
  // Extract control signals from register - use non-blocking for better timing
  always @(posedge aclk) begin
    data_in <= control_reg[0];
    data_valid <= control_reg[1];
    stuffing_active <= control_reg[2];
  end
  
  // Update status register
  always @(posedge aclk) begin
    status_reg <= {29'h0, stuff_error_reg, data_out_valid, data_out};
  end
  
  // Bit stuffing logic - refactored for better PPA
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      same_bit_count <= 3'b000;
      last_bit <= 1'b0;
      stuffed_bit <= 1'b0;
      data_out <= 1'b1;
      data_out_valid <= 1'b0;
      stuff_error_reg <= 1'b0;
    end else begin
      // Default state (no data transfer)
      data_out_valid <= 1'b0;
      
      // Check if active operation
      if (data_valid && stuffing_active) begin
        // Determine if we need to insert a stuff bit
        if (same_bit_count == 3'b100 && data_in == last_bit) begin
          // Insert stuff bit - separate conditions for clarity
          data_out <= ~last_bit;
          data_out_valid <= 1'b1;
          same_bit_count <= 3'b000;
          stuffed_bit <= 1'b1;
        end else begin
          // Normal bit processing
          data_out <= data_in;
          data_out_valid <= 1'b1;
          
          // Update bit counter based on incoming bit
          if (data_in == last_bit) begin
            // Same bit as before - increment counter
            same_bit_count <= same_bit_count + 3'b001;
          end else begin
            // Different bit - reset counter
            same_bit_count <= 3'b000;
          end
          
          // Update last bit
          last_bit <= data_in;
          stuffed_bit <= 1'b0;
        end
      end
    end
  end
  
  // Connect status output
  assign stuff_error = stuff_error_reg;

endmodule