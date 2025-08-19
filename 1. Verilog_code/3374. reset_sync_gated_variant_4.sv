//SystemVerilog
module reset_sync_gated_axi (
  // Clock and reset
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // AXI4-Lite write address channel
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,
  input  wire [31:0] s_axi_awaddr,
  input  wire [2:0]  s_axi_awprot,
  
  // AXI4-Lite write data channel
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  
  // AXI4-Lite write response channel
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,
  output reg  [1:0]  s_axi_bresp,
  
  // AXI4-Lite read address channel
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,
  input  wire [31:0] s_axi_araddr,
  input  wire [2:0]  s_axi_arprot,
  
  // AXI4-Lite read data channel
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready,
  output reg  [31:0] s_axi_rdata,
  output reg  [1:0]  s_axi_rresp,
  
  // Original output
  output reg         synced_rst
);

  // Register addresses
  localparam GATE_EN_ADDR    = 4'h0;
  localparam SYNCED_RST_ADDR = 4'h4;
  
  // Internal signals
  reg gate_en;
  reg flp;
  
  // AXI-Lite state definitions
  localparam IDLE = 2'b00;
  localparam ADDR = 2'b01;
  localparam DATA = 2'b10;
  localparam RESP = 2'b11;
  
  // AXI-Lite state registers
  reg [1:0] write_state;
  reg [1:0] read_state;
  reg [3:0] write_addr;
  reg [3:0] read_addr;
  
  //======================================================
  // Reset synchronization logic
  //======================================================
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      flp <= 1'b0;
    end else if(gate_en) begin
      flp <= 1'b1;
    end
  end
  
  // Second stage of reset synchronization
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      synced_rst <= 1'b0;
    end else if(gate_en) begin
      synced_rst <= flp;
    end
  end
  
  //======================================================
  // AXI4-Lite write channel control
  //======================================================
  // Write state machine - state transitions
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      write_state <= IDLE;
    end else begin
      case(write_state)
        IDLE: begin
          if(s_axi_awvalid && s_axi_awready) begin
            write_state <= DATA;
          end
        end
        
        DATA: begin
          if(s_axi_wvalid && s_axi_wready) begin
            write_state <= RESP;
          end
        end
        
        RESP: begin
          if(s_axi_bready && s_axi_bvalid) begin
            write_state <= IDLE;
          end
        end
        
        default: write_state <= IDLE;
      endcase
    end
  end
  
  // Write address channel control
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      write_addr    <= 4'h0;
    end else begin
      case(write_state)
        IDLE: begin
          s_axi_awready <= 1'b1;
          if(s_axi_awvalid && s_axi_awready) begin
            write_addr    <= s_axi_awaddr[3:0];
            s_axi_awready <= 1'b0;
          end
        end
        
        RESP: begin
          if(s_axi_bready && s_axi_bvalid) begin
            s_axi_awready <= 1'b1;
          end
        end
        
        default: begin
          // Keep awready low in other states
          s_axi_awready <= 1'b0;
        end
      endcase
    end
  end
  
  // Write data channel control
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      s_axi_wready <= 1'b0;
      gate_en      <= 1'b0;
    end else begin
      case(write_state)
        IDLE: begin
          s_axi_wready <= 1'b0;
        end
        
        DATA: begin
          s_axi_wready <= 1'b1;
          if(s_axi_wvalid && s_axi_wready) begin
            s_axi_wready <= 1'b0;
            
            // Write to appropriate register
            if(write_addr == GATE_EN_ADDR) begin
              gate_en <= s_axi_wdata[0];
            end
          end
        end
        
        default: begin
          s_axi_wready <= 1'b0;
        end
      endcase
    end
  end
  
  // Write response channel control
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= 2'b00;
    end else begin
      case(write_state)
        DATA: begin
          if(s_axi_wvalid && s_axi_wready) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;  // OKAY response
          end
        end
        
        RESP: begin
          if(s_axi_bready && s_axi_bvalid) begin
            s_axi_bvalid <= 1'b0;
          end
        end
        
        default: begin
          s_axi_bvalid <= 1'b0;
        end
      endcase
    end
  end
  
  //======================================================
  // AXI4-Lite read channel control
  //======================================================
  // Read state machine - state transitions
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      read_state <= IDLE;
    end else begin
      case(read_state)
        IDLE: begin
          if(s_axi_arvalid && s_axi_arready) begin
            read_state <= DATA;
          end
        end
        
        DATA: begin
          read_state <= RESP;
        end
        
        RESP: begin
          if(s_axi_rready && s_axi_rvalid) begin
            read_state <= IDLE;
          end
        end
        
        default: read_state <= IDLE;
      endcase
    end
  end
  
  // Read address channel control
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      read_addr     <= 4'h0;
    end else begin
      case(read_state)
        IDLE: begin
          s_axi_arready <= 1'b1;
          if(s_axi_arvalid && s_axi_arready) begin
            read_addr     <= s_axi_araddr[3:0];
            s_axi_arready <= 1'b0;
          end
        end
        
        RESP: begin
          if(s_axi_rready && s_axi_rvalid) begin
            s_axi_arready <= 1'b1;
          end
        end
        
        default: begin
          s_axi_arready <= 1'b0;
        end
      endcase
    end
  end
  
  // Read data channel control
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if(!s_axi_aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= 32'h0;
      s_axi_rresp  <= 2'b00;
    end else begin
      case(read_state)
        DATA: begin
          s_axi_rvalid <= 1'b1;
          s_axi_rresp  <= 2'b00;  // OKAY response
          
          // Read from appropriate register
          case(read_addr)
            GATE_EN_ADDR:    s_axi_rdata <= {31'b0, gate_en};
            SYNCED_RST_ADDR: s_axi_rdata <= {31'b0, synced_rst};
            default:         s_axi_rdata <= 32'h0;
          endcase
        end
        
        RESP: begin
          if(s_axi_rready && s_axi_rvalid) begin
            s_axi_rvalid <= 1'b0;
          end
        end
        
        default: begin
          s_axi_rvalid <= 1'b0;
        end
      endcase
    end
  end

endmodule