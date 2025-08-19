//SystemVerilog
module token_ring_arbiter_axi4lite (
  // AXI4-Lite Interface
  // Global Signals
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // Write Address Channel
  input  wire [31:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,
  
  // Write Data Channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,
  
  // Write Response Channel
  output reg  [1:0]  s_axi_bresp,
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // Read Address Channel
  input  wire [31:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,
  
  // Read Data Channel
  output reg  [31:0] s_axi_rdata,
  output reg  [1:0]  s_axi_rresp,
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // Original interface outputs exposed as module outputs
  output wire [3:0]  grant,
  output wire [1:0]  token
);

  // AXI4-Lite Response Codes
  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  
  // Register Addresses
  localparam ADDR_REQ   = 4'h0; // Request register: 0x00
  localparam ADDR_GRANT = 4'h4; // Grant register: 0x04
  localparam ADDR_TOKEN = 4'h8; // Token register: 0x08
  localparam ADDR_CTRL  = 4'hC; // Control register: 0x0C
  
  // Internal signals
  reg [3:0]  req_reg;
  reg        rst_reg;
  
  // Pipeline stage registers (from original design)
  reg [3:0]  req_stage1;
  reg [1:0]  token_stage1;
  
  reg [3:0]  grant_internal;
  reg [1:0]  token_internal;
  reg        valid_stage1, valid_stage2;
  
  // AXI4-Lite interface state machine states - one-hot encoded
  localparam IDLE           = 6'b000001;
  localparam WRITE_ADDR     = 6'b000010;
  localparam WRITE_DATA     = 6'b000100;
  localparam WRITE_RESPONSE = 6'b001000;
  localparam READ_ADDR      = 6'b010000;
  localparam READ_DATA      = 6'b100000;
  
  // AXI state machines
  reg [5:0] write_state;
  reg [5:0] read_state;
  reg [31:0] read_addr, write_addr;
  reg [31:0] write_data;
  reg [3:0]  write_strb;
  
  // Output assignments
  assign grant = grant_internal;
  assign token = token_internal;
  
  // Reset logic and initialization
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      write_state <= IDLE;
      read_state <= IDLE;
      
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_arready <= 1'b0;
      s_axi_rvalid <= 1'b0;
      
      req_reg <= 4'b0;
      rst_reg <= 1'b1;
    end else begin
      // Default reset state cleared after reset
      rst_reg <= 1'b0;
    end
  end
  
  // AXI4-Lite Write Transaction State Machine
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      write_state <= IDLE;
    end else begin
      case (write_state)
        IDLE: begin
          if (s_axi_awvalid) begin
            write_addr <= s_axi_awaddr;
            s_axi_awready <= 1'b1;
            write_state <= WRITE_ADDR;
          end
        end
        
        WRITE_ADDR: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            write_data <= s_axi_wdata;
            write_strb <= s_axi_wstrb;
            s_axi_wready <= 1'b1;
            write_state <= WRITE_DATA;
          end
        end
        
        WRITE_DATA: begin
          s_axi_wready <= 1'b0;
          
          // Process the write based on address
          case (write_addr[3:0])
            ADDR_REQ: begin
              req_reg <= write_data[3:0];
              s_axi_bresp <= RESP_OKAY;
            end
            
            ADDR_CTRL: begin
              if (write_data[0])
                rst_reg <= 1'b1;
              s_axi_bresp <= RESP_OKAY;
            end
            
            default: begin
              // Token and Grant are read-only
              s_axi_bresp <= RESP_SLVERR;
            end
          endcase
          
          s_axi_bvalid <= 1'b1;
          write_state <= WRITE_RESPONSE;
        end
        
        WRITE_RESPONSE: begin
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            write_state <= IDLE;
          end
        end
        
        default: write_state <= IDLE;
      endcase
    end
  end
  
  // AXI4-Lite Read Transaction State Machine
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      read_state <= IDLE;
    end else begin
      case (read_state)
        IDLE: begin
          if (s_axi_arvalid) begin
            read_addr <= s_axi_araddr;
            s_axi_arready <= 1'b1;
            read_state <= READ_ADDR;
          end
        end
        
        READ_ADDR: begin
          s_axi_arready <= 1'b0;
          
          // Set the read data based on address
          case (read_addr[3:0])
            ADDR_REQ: begin
              s_axi_rdata <= {28'b0, req_reg};
              s_axi_rresp <= RESP_OKAY;
            end
            
            ADDR_GRANT: begin
              s_axi_rdata <= {28'b0, grant_internal};
              s_axi_rresp <= RESP_OKAY;
            end
            
            ADDR_TOKEN: begin
              s_axi_rdata <= {30'b0, token_internal};
              s_axi_rresp <= RESP_OKAY;
            end
            
            ADDR_CTRL: begin
              s_axi_rdata <= {31'b0, rst_reg};
              s_axi_rresp <= RESP_OKAY;
            end
            
            default: begin
              s_axi_rdata <= 32'b0;
              s_axi_rresp <= RESP_SLVERR;
            end
          endcase
          
          s_axi_rvalid <= 1'b1;
          read_state <= READ_DATA;
        end
        
        READ_DATA: begin
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            read_state <= IDLE;
          end
        end
        
        default: read_state <= IDLE;
      endcase
    end
  end
  
  // First pipeline stage - register inputs
  always @(posedge s_axi_aclk) begin
    if (rst_reg) begin
      req_stage1 <= 4'b0;
      token_stage1 <= 2'd0;
      valid_stage1 <= 1'b0;
    end else begin
      req_stage1 <= req_reg;
      token_stage1 <= token_internal;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Second pipeline stage - arbiter logic (unchanged core functionality)
  always @(posedge s_axi_aclk) begin
    if (rst_reg) begin
      grant_internal <= 4'd0;
      token_internal <= 2'd0;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      grant_internal <= 4'd0;
      case (token_stage1)
        2'd0: if (req_stage1[0]) begin
                grant_internal[0] <= 1'b1;
              end else if (req_stage1[1]) begin 
                grant_internal[1] <= 1'b1; 
                token_internal <= 2'd1; 
              end else if (req_stage1[2]) begin 
                grant_internal[2] <= 1'b1; 
                token_internal <= 2'd2; 
              end else if (req_stage1[3]) begin 
                grant_internal[3] <= 1'b1; 
                token_internal <= 2'd3; 
              end
        
        2'd1: if (req_stage1[1]) begin
                grant_internal[1] <= 1'b1;
              end else if (req_stage1[2]) begin 
                grant_internal[2] <= 1'b1; 
                token_internal <= 2'd2; 
              end else if (req_stage1[3]) begin 
                grant_internal[3] <= 1'b1; 
                token_internal <= 2'd3; 
              end else if (req_stage1[0]) begin 
                grant_internal[0] <= 1'b1; 
                token_internal <= 2'd0; 
              end
        
        2'd2: if (req_stage1[2]) begin
                grant_internal[2] <= 1'b1;
              end else if (req_stage1[3]) begin 
                grant_internal[3] <= 1'b1; 
                token_internal <= 2'd3; 
              end else if (req_stage1[0]) begin 
                grant_internal[0] <= 1'b1; 
                token_internal <= 2'd0; 
              end else if (req_stage1[1]) begin 
                grant_internal[1] <= 1'b1; 
                token_internal <= 2'd1; 
              end
        
        2'd3: if (req_stage1[3]) begin
                grant_internal[3] <= 1'b1;
              end else if (req_stage1[0]) begin 
                grant_internal[0] <= 1'b1; 
                token_internal <= 2'd0; 
              end else if (req_stage1[1]) begin 
                grant_internal[1] <= 1'b1; 
                token_internal <= 2'd1; 
              end else if (req_stage1[2]) begin 
                grant_internal[2] <= 1'b1; 
                token_internal <= 2'd2; 
              end
      endcase
      valid_stage2 <= 1'b1;
    end
  end
  
endmodule