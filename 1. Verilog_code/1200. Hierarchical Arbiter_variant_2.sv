//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module hierarchical_arbiter_axi4lite #(
  parameter C_S_AXI_ADDR_WIDTH = 4,
  parameter C_S_AXI_DATA_WIDTH = 32
)(
  // AXI4-Lite Interface
  input  wire                               s_axi_aclk,
  input  wire                               s_axi_aresetn,
  // AXI4-Lite Write Address Channel
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
  input  wire                               s_axi_awvalid,
  output reg                                s_axi_awready,
  // AXI4-Lite Write Data Channel
  input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
  input  wire                               s_axi_wvalid,
  output reg                                s_axi_wready,
  // AXI4-Lite Write Response Channel
  output reg  [1:0]                         s_axi_bresp,
  output reg                                s_axi_bvalid,
  input  wire                               s_axi_bready,
  // AXI4-Lite Read Address Channel
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
  input  wire                               s_axi_arvalid,
  output reg                                s_axi_arready,
  // AXI4-Lite Read Data Channel
  output reg  [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
  output reg  [1:0]                         s_axi_rresp,
  output reg                                s_axi_rvalid,
  input  wire                               s_axi_rready
);

  // AXI4-Lite response codes
  localparam RESP_OKAY = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  
  // Memory map registers
  localparam REG_REQUESTS_ADDR = 4'h0;  // Requests register address
  localparam REG_GRANTS_ADDR = 4'h4;    // Grants register address
  
  // Internal signals
  reg [7:0] requests_reg;               // Storage for requests
  reg [7:0] grants_reg;                 // Storage for grants
  
  // Arbiter logic signals
  reg [1:0] group_reqs;
  reg [1:0] group_grants;
  reg [3:0] sub_grants [0:1];
  
  // AXI write state machine - One-hot encoding
  reg [2:0] write_state; // 3 bits for 3 states
  localparam WRITE_IDLE = 3'b001; // One-hot encoded
  localparam WRITE_DATA = 3'b010; // One-hot encoded
  localparam WRITE_RESP = 3'b100; // One-hot encoded
  
  // AXI read state machine - One-hot encoding
  reg [1:0] read_state; // 2 bits for 2 states
  localparam READ_IDLE = 2'b01; // One-hot encoded
  localparam READ_DATA = 2'b10; // One-hot encoded
  
  // Registered address signals
  reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
  reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
  
  // Write transaction handling
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= RESP_OKAY;
      axi_awaddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
      write_state <= WRITE_IDLE;
      requests_reg <= 8'h00;
    end else begin
      case (1'b1) // One-hot case statement
        write_state[0]: begin // WRITE_IDLE
          if (s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
            axi_awaddr_reg <= s_axi_awaddr;
            write_state <= WRITE_DATA;
          end
        end
        
        write_state[1]: begin // WRITE_DATA
          s_axi_awready <= 1'b0;
          
          if (s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
            
            // Handle write data based on address
            case (axi_awaddr_reg)
              REG_REQUESTS_ADDR: begin
                if (s_axi_wstrb[0]) 
                  requests_reg <= s_axi_wdata[7:0];
              end
              default: begin
                // Invalid address - respond with slave error
                s_axi_bresp <= RESP_SLVERR;
              end
            endcase
            
            write_state <= WRITE_RESP;
          end
        end
        
        write_state[2]: begin // WRITE_RESP
          s_axi_wready <= 1'b0;
          s_axi_bvalid <= 1'b1;
          
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            write_state <= WRITE_IDLE;
          end
        end
        
        default: begin
          write_state <= WRITE_IDLE;
        end
      endcase
    end
  end
  
  // Read transaction handling
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= RESP_OKAY;
      axi_araddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
      read_state <= READ_IDLE;
    end else begin
      case (1'b1) // One-hot case statement
        read_state[0]: begin // READ_IDLE
          if (s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
            axi_araddr_reg <= s_axi_araddr;
            read_state <= READ_DATA;
          end
        end
        
        read_state[1]: begin // READ_DATA
          s_axi_arready <= 1'b0;
          s_axi_rvalid <= 1'b1;
          
          // Provide read data based on address
          case (axi_araddr_reg)
            REG_REQUESTS_ADDR: begin
              s_axi_rdata <= {24'h000000, requests_reg};
              s_axi_rresp <= RESP_OKAY;
            end
            REG_GRANTS_ADDR: begin
              s_axi_rdata <= {24'h000000, grants_reg};
              s_axi_rresp <= RESP_OKAY;
            end
            default: begin
              s_axi_rdata <= 32'h00000000;
              s_axi_rresp <= RESP_SLVERR;
            end
          endcase
          
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        
        default: begin
          read_state <= READ_IDLE;
        end
      endcase
    end
  end
  
  // Arbiter logic - core functionality from original design
  always @(*) begin
    group_reqs[0] = |requests_reg[3:0];
    group_reqs[1] = |requests_reg[7:4];
  
    // Top-level arbiter
    group_grants[0] = group_reqs[0] & ~group_reqs[1];
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
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      grants_reg <= 8'h00;
    else
      grants_reg <= {sub_grants[1], sub_grants[0]};
  end

endmodule

`default_nettype wire