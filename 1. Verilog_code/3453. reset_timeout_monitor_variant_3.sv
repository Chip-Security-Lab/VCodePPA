//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_timeout_monitor (
  // Global signals
  input wire aclk,                    // AXI Clock
  input wire aresetn,                 // AXI Reset, active low
  
  // AXI4-Lite Slave Interface - Write Address Channel
  input wire [31:0] s_axi_awaddr,     // Write address
  input wire [2:0] s_axi_awprot,      // Write protection type
  input wire s_axi_awvalid,           // Write address valid
  output wire s_axi_awready,          // Write address ready
  
  // AXI4-Lite Slave Interface - Write Data Channel
  input wire [31:0] s_axi_wdata,      // Write data
  input wire [3:0] s_axi_wstrb,       // Write strobes
  input wire s_axi_wvalid,            // Write valid
  output wire s_axi_wready,           // Write ready
  
  // AXI4-Lite Slave Interface - Write Response Channel
  output wire [1:0] s_axi_bresp,      // Write response
  output wire s_axi_bvalid,           // Write response valid
  input wire s_axi_bready,            // Response ready
  
  // AXI4-Lite Slave Interface - Read Address Channel
  input wire [31:0] s_axi_araddr,     // Read address
  input wire [2:0] s_axi_arprot,      // Read protection type
  input wire s_axi_arvalid,           // Read address valid
  output wire s_axi_arready,          // Read address ready
  
  // AXI4-Lite Slave Interface - Read Data Channel
  output wire [31:0] s_axi_rdata,     // Read data
  output wire [1:0] s_axi_rresp,      // Read response
  output wire s_axi_rvalid,           // Read valid
  input wire s_axi_rready             // Read ready
);

  // Internal registers
  reg [7:0] timeout_counter;
  reg reset_timeout_error;
  
  // Register map (byte addresses)
  localparam ADDR_TIMEOUT      = 4'h0;    // Read-only timeout counter value
  localparam ADDR_ERROR_STATUS = 4'h4;    // Read-only error status
  localparam ADDR_CONTROL      = 4'h8;    // Write-only control register

  // AXI4-Lite interface control signals
  reg axi_awready;
  reg axi_wready;
  reg axi_bvalid;
  reg axi_arready;
  reg axi_rvalid;
  reg [1:0] axi_bresp;
  reg [1:0] axi_rresp;
  reg [31:0] axi_rdata;
  
  // Address latching registers
  reg [3:0] axi_awaddr;
  reg [3:0] axi_araddr;
  
  // Control signals
  reg write_in_progress;
  reg read_in_progress;
  reg [31:0] reg_data_out;
  
  // Core functionality - timeout counter with optimized reset logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      timeout_counter <= 8'd0;
      reset_timeout_error <= 1'b0;
    end else begin
      if (write_in_progress && axi_awaddr == ADDR_CONTROL && s_axi_wstrb[0] && s_axi_wdata[1]) begin
        timeout_counter <= 8'd0; // Reset on explicit command
      end else if (timeout_counter < 8'hFF) begin
        timeout_counter <= timeout_counter + 8'd1;
      end else if (timeout_counter == 8'hFF && !reset_timeout_error) begin
        reset_timeout_error <= 1'b1;
      end
      
      // Clear error flag on command
      if (write_in_progress && axi_awaddr == ADDR_CONTROL && s_axi_wstrb[0] && s_axi_wdata[0]) begin
        reset_timeout_error <= 1'b0;
      end
    end
  end
  
  // Write transaction state machine
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      axi_awready <= 1'b1; // Ready to accept address after reset
      axi_wready <= 1'b0;
      axi_bvalid <= 1'b0;
      axi_bresp <= 2'b00;
      axi_awaddr <= 4'h0;
      write_in_progress <= 1'b0;
    end else begin
      // Write Address Channel handshake
      if (axi_awready && s_axi_awvalid) begin
        axi_awready <= 1'b0; // Not ready for new address until transaction completes
        axi_wready <= 1'b1;  // Ready for write data
        axi_awaddr <= s_axi_awaddr[3:0];
        write_in_progress <= 1'b1;
      end
      
      // Write Data Channel handshake
      if (axi_wready && s_axi_wvalid) begin
        axi_wready <= 1'b0;  // Accept only one data transfer
        axi_bvalid <= 1'b1;  // Indicate write response is valid
      end
      
      // Write Response Channel handshake
      if (axi_bvalid && s_axi_bready) begin
        axi_bvalid <= 1'b0;
        axi_awready <= 1'b1; // Ready for new address
        write_in_progress <= 1'b0;
      end
    end
  end
  
  // Read transaction state machine
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      axi_arready <= 1'b1; // Ready to accept address after reset
      axi_rvalid <= 1'b0;
      axi_rresp <= 2'b00;
      axi_araddr <= 4'h0;
      read_in_progress <= 1'b0;
    end else begin
      // Read Address Channel handshake
      if (axi_arready && s_axi_arvalid) begin
        axi_arready <= 1'b0; // Not ready for new address until transaction completes
        axi_araddr <= s_axi_araddr[3:0];
        read_in_progress <= 1'b1;
        
        // Prepare read data immediately after capturing address
        case (s_axi_araddr[3:0])
          ADDR_TIMEOUT: reg_data_out <= {24'd0, timeout_counter};
          ADDR_ERROR_STATUS: reg_data_out <= {31'd0, reset_timeout_error};
          default: reg_data_out <= 32'd0;
        endcase
        
        axi_rvalid <= 1'b1;  // Data will be valid on next cycle
      end
      
      // Read Data Channel handshake
      if (axi_rvalid && s_axi_rready) begin
        axi_rvalid <= 1'b0;
        axi_arready <= 1'b1; // Ready for new address
        read_in_progress <= 1'b0;
      end
    end
  end
  
  // Capture read data
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      axi_rdata <= 32'd0;
    end else if (axi_arready && s_axi_arvalid) begin
      axi_rdata <= reg_data_out;
    end
  end
  
  // Assign outputs
  assign s_axi_awready = axi_awready;
  assign s_axi_wready = axi_wready;
  assign s_axi_bresp = axi_bresp;
  assign s_axi_bvalid = axi_bvalid;
  assign s_axi_arready = axi_arready;
  assign s_axi_rresp = axi_rresp;
  assign s_axi_rvalid = axi_rvalid;
  assign s_axi_rdata = axi_rdata;

endmodule