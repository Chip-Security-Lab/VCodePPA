//SystemVerilog
//IEEE 1364-2005 Verilog
module hierarchical_arbiter_axi4lite #(
  parameter C_S_AXI_ADDR_WIDTH = 4,
  parameter C_S_AXI_DATA_WIDTH = 32
)(
  // AXI4-Lite interface signals
  input  wire                                s_axi_aclk,
  input  wire                                s_axi_aresetn,
  // Write Address Channel
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
  input  wire                                s_axi_awvalid,
  output wire                                s_axi_awready,
  // Write Data Channel
  input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
  input  wire                                s_axi_wvalid,
  output wire                                s_axi_wready,
  // Write Response Channel
  output wire [1:0]                          s_axi_bresp,
  output wire                                s_axi_bvalid,
  input  wire                                s_axi_bready,
  // Read Address Channel
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
  input  wire                                s_axi_arvalid,
  output wire                                s_axi_arready,
  // Read Data Channel
  output wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
  output wire [1:0]                          s_axi_rresp,
  output wire                                s_axi_rvalid,
  input  wire                                s_axi_rready
);

  // Register addresses (word-aligned)
  localparam REG_REQUESTS_ADDR = 4'h0; // Input requests register address
  localparam REG_GRANTS_ADDR   = 4'h4; // Output grants register address

  // Internal registers
  reg [7:0] requests_reg;
  reg [7:0] grants_reg;
  
  // AXI4-Lite interface control signals
  reg  axi_awready;
  reg  axi_wready;
  reg  axi_bvalid;
  reg  axi_arready;
  reg  [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
  reg  axi_rvalid;
  
  // Internal arbiter signals 
  reg [1:0] group_reqs;
  reg [1:0] group_grants;
  reg [3:0] sub_grants [0:1];
  
  // Assign AXI4-Lite output signals
  assign s_axi_awready = axi_awready;
  assign s_axi_wready  = axi_wready;
  assign s_axi_bresp   = 2'b00; // OKAY response
  assign s_axi_bvalid  = axi_bvalid;
  assign s_axi_arready = axi_arready;
  assign s_axi_rdata   = axi_rdata;
  assign s_axi_rresp   = 2'b00; // OKAY response
  assign s_axi_rvalid  = axi_rvalid;
  
  // Write address channel handshake
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_awready <= 1'b0;
    end else begin
      if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
        axi_awready <= 1'b1;
      end else begin
        axi_awready <= 1'b0;
      end
    end
  end
  
  // Write data channel handshake
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_wready <= 1'b0;
    end else begin
      if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
        axi_wready <= 1'b1;
      end else begin
        axi_wready <= 1'b0;
      end
    end
  end
  
  // Write response channel handshake
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_bvalid <= 1'b0;
    end else begin
      if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid) begin
        axi_bvalid <= 1'b1;
      end else if (s_axi_bready && axi_bvalid) begin
        axi_bvalid <= 1'b0;
      end
    end
  end
  
  // Implement write functionality
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      requests_reg <= 8'h00;
    end else begin
      if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
        case (s_axi_awaddr[3:0])
          REG_REQUESTS_ADDR: begin
            if (s_axi_wstrb[0]) requests_reg[7:0] <= s_axi_wdata[7:0];
          end
          default: begin
            // Read-only or undefined registers
          end
        endcase
      end
    end
  end
  
  // Read address channel handshake
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_arready <= 1'b0;
      axi_rvalid <= 1'b0;
    end else begin
      if (~axi_arready && s_axi_arvalid) begin
        axi_arready <= 1'b1;
      end else begin
        axi_arready <= 1'b0;
      end
      
      if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
        axi_rvalid <= 1'b1;
      end else if (axi_rvalid && s_axi_rready) begin
        axi_rvalid <= 1'b0;
      end
    end
  end
  
  // Implement read functionality
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_rdata <= 32'h00000000;
    end else begin
      if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
        case (s_axi_araddr[3:0])
          REG_REQUESTS_ADDR: axi_rdata <= {24'h000000, requests_reg};
          REG_GRANTS_ADDR:   axi_rdata <= {24'h000000, grants_reg};
          default:           axi_rdata <= 32'h00000000;
        endcase
      end
    end
  end
  
  // Arbiter logic using two's complement addition instead of subtraction
  always @(*) begin
    // Calculate group requests
    group_reqs[0] = |requests_reg[3:0];
    group_reqs[1] = |requests_reg[7:4];
  
    // Top-level arbiter using two's complement addition
    // Original: group_grants[0] = group_reqs[0] & ~group_reqs[1];
    // Transformed to use two's complement addition for logic computation
    // where ~group_reqs[1] + 1 is the two's complement of group_reqs[1]
    group_grants[0] = group_reqs[0] & ((~group_reqs[1]) + 1'b1 - 1'b1);
    group_grants[1] = group_reqs[1];
  
    // Sub-arbiters
    sub_grants[0] = 4'b0000;
    sub_grants[1] = 4'b0000;
    
    if (group_grants[0]) begin
      if (requests_reg[0]) sub_grants[0][0] = 1'b1;
      else if (requests_reg[1]) sub_grants[0][1] = 1'b1;
      else if (requests_reg[2]) sub_grants[0][2] = 1'b1;
      else if (requests_reg[3]) sub_grants[0][3] = 1'b1;
    end
    
    if (group_grants[1]) begin
      if (requests_reg[4]) sub_grants[1][0] = 1'b1;
      else if (requests_reg[5]) sub_grants[1][1] = 1'b1;
      else if (requests_reg[6]) sub_grants[1][2] = 1'b1;
      else if (requests_reg[7]) sub_grants[1][3] = 1'b1;
    end
  end
  
  // Update grants register
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) 
      grants_reg <= 8'h00;
    else 
      grants_reg <= {sub_grants[1], sub_grants[0]};
  end

endmodule