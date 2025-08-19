//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_gated_axi (
  // Clock and reset
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // AXI4-Lite write address channel
  input  wire [31:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,
  
  // AXI4-Lite write data channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,
  
  // AXI4-Lite write response channel
  output reg  [1:0]  s_axi_bresp,
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // AXI4-Lite read address channel
  input  wire [31:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,
  
  // AXI4-Lite read data channel
  output reg  [31:0] s_axi_rdata,
  output reg  [1:0]  s_axi_rresp,
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // Original external reset input
  input  wire        ext_rst_n,
  
  // Synchronized reset output
  output reg         synced_rst
);

  // Internal registers
  reg  flp;
  reg  gate_en_reg;
  
  // Address offset definitions
  localparam ADDR_CONTROL = 4'h0;
  localparam ADDR_STATUS  = 4'h4;
  
  // Response codes
  localparam RESP_OKAY    = 2'b00;
  localparam RESP_SLVERR  = 2'b10;
  
  // Buffered high fanout signals
  reg s_axi_aclk_buf1, s_axi_aclk_buf2, s_axi_aclk_buf3;
  reg s_axi_bready_buf1, s_axi_bready_buf2;
  reg ext_rst_n_buf;
  reg [1:0] resp_okay_buf;
  reg [1:0] resp_slverr_buf;
  
  // Fanout buffering for high fanout clocks and resets
  always @(*) begin
    s_axi_aclk_buf1 = s_axi_aclk;
    s_axi_aclk_buf2 = s_axi_aclk;
    s_axi_aclk_buf3 = s_axi_aclk;
    
    s_axi_bready_buf1 = s_axi_bready;
    s_axi_bready_buf2 = s_axi_bready;
    
    ext_rst_n_buf = ext_rst_n;
    
    resp_okay_buf = RESP_OKAY;
    resp_slverr_buf = RESP_SLVERR;
  end
  
  // Write address channel state
  reg write_addr_valid;
  reg [31:0] write_addr;
  
  // Write data channel state
  reg write_data_valid;
  reg [31:0] write_data;
  reg [3:0] write_strb;
  
  // Read address channel state
  reg read_addr_valid;
  reg [31:0] read_addr;
  
  // Write address channel logic
  always @(posedge s_axi_aclk_buf1 or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      write_addr_valid <= 1'b0;
      write_addr <= 32'h0;
    end else begin
      if (~s_axi_awready && s_axi_awvalid && ~write_addr_valid) begin
        s_axi_awready <= 1'b1;
        write_addr_valid <= 1'b1;
        write_addr <= s_axi_awaddr;
      end else begin
        s_axi_awready <= 1'b0;
        if (write_data_valid && write_addr_valid && s_axi_bready_buf1 && s_axi_bvalid) begin
          write_addr_valid <= 1'b0;
        end
      end
    end
  end
  
  // Write data channel logic
  always @(posedge s_axi_aclk_buf2 or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_wready <= 1'b0;
      write_data_valid <= 1'b0;
      write_data <= 32'h0;
      write_strb <= 4'h0;
    end else begin
      if (~s_axi_wready && s_axi_wvalid && ~write_data_valid) begin
        s_axi_wready <= 1'b1;
        write_data_valid <= 1'b1;
        write_data <= s_axi_wdata;
        write_strb <= s_axi_wstrb;
      end else begin
        s_axi_wready <= 1'b0;
        if (write_data_valid && write_addr_valid && s_axi_bready_buf2 && s_axi_bvalid) begin
          write_data_valid <= 1'b0;
        end
      end
    end
  end
  
  // Write response channel logic
  always @(posedge s_axi_aclk_buf3 or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= resp_okay_buf;
      gate_en_reg <= 1'b0;
    end else begin
      if (write_addr_valid && write_data_valid && ~s_axi_bvalid) begin
        s_axi_bvalid <= 1'b1;
        
        case (write_addr[3:0])
          ADDR_CONTROL: begin
            if (write_strb[0]) begin
              gate_en_reg <= write_data[0];
              s_axi_bresp <= resp_okay_buf;
            end else begin
              s_axi_bresp <= resp_slverr_buf;
            end
          end
          default: s_axi_bresp <= resp_slverr_buf;
        endcase
      end else begin
        if (s_axi_bready && s_axi_bvalid) begin
          s_axi_bvalid <= 1'b0;
        end
      end
    end
  end
  
  // Read address channel logic
  always @(posedge s_axi_aclk_buf1 or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      read_addr_valid <= 1'b0;
      read_addr <= 32'h0;
    end else begin
      if (~s_axi_arready && s_axi_arvalid && ~read_addr_valid) begin
        s_axi_arready <= 1'b1;
        read_addr_valid <= 1'b1;
        read_addr <= s_axi_araddr;
      end else begin
        s_axi_arready <= 1'b0;
        if (read_addr_valid && s_axi_rready && s_axi_rvalid) begin
          read_addr_valid <= 1'b0;
        end
      end
    end
  end
  
  // Read data channel logic
  always @(posedge s_axi_aclk_buf2 or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= resp_okay_buf;
      s_axi_rdata <= 32'h0;
    end else begin
      if (read_addr_valid && ~s_axi_rvalid) begin
        s_axi_rvalid <= 1'b1;
        
        case (read_addr[3:0])
          ADDR_CONTROL: begin
            s_axi_rdata <= {31'b0, gate_en_reg};
            s_axi_rresp <= resp_okay_buf;
          end
          ADDR_STATUS: begin
            s_axi_rdata <= {31'b0, synced_rst};
            s_axi_rresp <= resp_okay_buf;
          end
          default: begin
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= resp_slverr_buf;
          end
        endcase
      end else begin
        if (s_axi_rready && s_axi_rvalid) begin
          s_axi_rvalid <= 1'b0;
        end
      end
    end
  end
  
  // Core reset synchronization logic (original functionality)
  always @(posedge s_axi_aclk_buf3 or negedge ext_rst_n_buf) begin
    if (!ext_rst_n_buf) begin
      flp <= 1'b0;
      synced_rst <= 1'b0;
    end else if (gate_en_reg) begin
      flp <= 1'b1;
      synced_rst <= flp;
    end
  end

endmodule