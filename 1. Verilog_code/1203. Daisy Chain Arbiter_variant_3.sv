//SystemVerilog
module daisy_chain_arbiter_axi(
  // Global signals
  input wire s_axi_aclk,
  input wire s_axi_aresetn,
  
  // AXI4-Lite write address channel
  input wire [31:0] s_axi_awaddr,
  input wire s_axi_awvalid,
  output wire s_axi_awready,
  
  // AXI4-Lite write data channel
  input wire [31:0] s_axi_wdata,
  input wire [3:0] s_axi_wstrb,
  input wire s_axi_wvalid,
  output wire s_axi_wready,
  
  // AXI4-Lite write response channel
  output wire [1:0] s_axi_bresp,
  output wire s_axi_bvalid,
  input wire s_axi_bready,
  
  // AXI4-Lite read address channel
  input wire [31:0] s_axi_araddr,
  input wire s_axi_arvalid,
  output wire s_axi_arready,
  
  // AXI4-Lite read data channel
  output wire [31:0] s_axi_rdata,
  output wire [1:0] s_axi_rresp,
  output wire s_axi_rvalid,
  input wire s_axi_rready
);

  // Internal registers
  reg [3:0] request_reg;
  reg [3:0] grant_reg;
  reg write_active;
  reg read_active;
  
  // Register inputs to improve timing
  reg s_axi_awvalid_reg, s_axi_wvalid_reg, s_axi_bready_reg;
  reg s_axi_arvalid_reg, s_axi_rready_reg;
  reg [31:0] s_axi_awaddr_reg, s_axi_wdata_reg, s_axi_araddr_reg;
  reg [3:0] s_axi_wstrb_reg;
  
  // Internal signals for daisy chain arbiter
  wire [4:0] chain;
  assign chain[0] = 1'b1;  // First stage always has priority
  
  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin: daisy
      assign chain[i+1] = chain[i] & ~request_reg[i];
    end
  endgenerate
  
  // Register input signals
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      s_axi_awvalid_reg <= 1'b0;
      s_axi_wvalid_reg <= 1'b0;
      s_axi_bready_reg <= 1'b0;
      s_axi_arvalid_reg <= 1'b0;
      s_axi_rready_reg <= 1'b0;
      s_axi_awaddr_reg <= 32'h0;
      s_axi_wdata_reg <= 32'h0;
      s_axi_araddr_reg <= 32'h0;
      s_axi_wstrb_reg <= 4'h0;
    end else begin
      s_axi_awvalid_reg <= s_axi_awvalid;
      s_axi_wvalid_reg <= s_axi_wvalid;
      s_axi_bready_reg <= s_axi_bready;
      s_axi_arvalid_reg <= s_axi_arvalid;
      s_axi_rready_reg <= s_axi_rready;
      s_axi_awaddr_reg <= s_axi_awaddr;
      s_axi_wdata_reg <= s_axi_wdata;
      s_axi_araddr_reg <= s_axi_araddr;
      s_axi_wstrb_reg <= s_axi_wstrb;
    end
  end
  
  // AXI control signals
  reg [31:0] rd_data;
  wire write_valid = s_axi_awvalid_reg && s_axi_wvalid_reg;
  
  // Address decoding
  localparam ADDR_REQUEST = 4'h0;  // Register offset 0x00
  localparam ADDR_GRANT = 4'h4;    // Register offset 0x04
  
  // Pre-compute address decode logic to improve timing
  reg is_request_addr_w, is_request_addr_r;
  reg is_grant_addr_r;
  
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      is_request_addr_w <= 1'b0;
      is_request_addr_r <= 1'b0;
      is_grant_addr_r <= 1'b0;
    end else begin
      is_request_addr_w <= (s_axi_awaddr_reg[3:0] == ADDR_REQUEST);
      is_request_addr_r <= (s_axi_araddr_reg[3:0] == ADDR_REQUEST);
      is_grant_addr_r <= (s_axi_araddr_reg[3:0] == ADDR_GRANT);
    end
  end
  
  // Write channel control
  assign s_axi_awready = ~write_active;
  assign s_axi_wready = ~write_active;
  
  // Read channel control
  assign s_axi_arready = ~read_active;
  assign s_axi_rdata = rd_data;
  assign s_axi_rvalid = read_active;
  assign s_axi_rresp = 2'b00; // OKAY response
  
  // Write response channel
  assign s_axi_bvalid = write_active;
  assign s_axi_bresp = 2'b00; // OKAY response
  
  // Write operation
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      request_reg <= 4'h0;
      write_active <= 1'b0;
    end else begin
      // Handle write transaction
      if (write_valid && !write_active) begin
        write_active <= 1'b1;
        
        if (is_request_addr_w) begin
          request_reg <= s_axi_wdata_reg[3:0];
        end
      end
      else if (write_active && s_axi_bready_reg) begin
        write_active <= 1'b0;
      end
    end
  end
  
  // Read operation
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      read_active <= 1'b0;
      rd_data <= 32'h0;
    end else begin
      // Handle read transaction
      if (s_axi_arvalid_reg && !read_active) begin
        read_active <= 1'b1;
        
        if (is_request_addr_r)
          rd_data <= {28'b0, request_reg};
        else if (is_grant_addr_r)
          rd_data <= {28'b0, grant_reg};
        else
          rd_data <= 32'h0;
      end
      else if (read_active && s_axi_rready_reg) begin
        read_active <= 1'b0;
      end
    end
  end
  
  // Pre-compute request signals for better timing
  reg [3:0] request_and_chain;
  
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      request_and_chain <= 4'h0;
    end else begin
      request_and_chain[0] <= request_reg[0] & chain[0];
      request_and_chain[1] <= request_reg[1] & chain[1];
      request_and_chain[2] <= request_reg[2] & chain[2];
      request_and_chain[3] <= request_reg[3] & chain[3];
    end
  end
  
  // Core arbitration logic with pre-computed values
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      grant_reg <= 4'h0;
    end else begin
      grant_reg <= request_and_chain;
    end
  end

endmodule