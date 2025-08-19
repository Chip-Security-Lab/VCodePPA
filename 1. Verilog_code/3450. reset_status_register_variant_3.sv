//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_status_register (
  // Global signals
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // Write address channel
  input  wire [31:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  
  // Write data channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  
  // Write response channel
  output wire [1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // Read address channel
  input  wire [31:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  
  // Read data channel
  output wire [31:0] s_axi_rdata,
  output wire [1:0]  s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // Original reset inputs
  input  wire        pwr_rst,
  input  wire        wdt_rst,
  input  wire        sw_rst,
  input  wire        ext_rst
);

  // Register address (offset 0)
  localparam RESET_STATUS_ADDR = 4'h0;
  
  // Internal signals
  reg [7:0] rst_status;
  
  // Buffer registers for high fanout signals
  reg [3:0] clk_buf; // Clock buffer
  reg [1:0] IDLE_buf [0:1]; // IDLE state buffer
  reg [1:0] b1_buf [0:1]; // b1 buffer for state transitions
  
  // AXI4-Lite interface logic
  reg        awready;
  reg        wready;
  reg        bvalid;
  reg        arready;
  reg [31:0] rdata;
  reg        rvalid;
  
  // Address decoding state machine
  reg [1:0] write_state;
  reg [1:0] read_state;
  
  localparam IDLE = 2'b00;
  localparam ADDR = 2'b01;
  localparam DATA = 2'b10;
  localparam RESP = 2'b11;
  
  // Distribute high fanout signals through buffer registers
  always @(posedge s_axi_aclk) begin
    clk_buf[0] <= IDLE;
    clk_buf[1] <= clk_buf[0];
    clk_buf[2] <= clk_buf[1];
    clk_buf[3] <= clk_buf[2];
    
    IDLE_buf[0] <= IDLE;
    IDLE_buf[1] <= IDLE_buf[0];
    
    b1_buf[0] <= 2'b01;
    b1_buf[1] <= b1_buf[0];
  end
  
  // Fanout buffer for rst_status
  reg [7:0] rst_status_buf [0:1];
  
  always @(posedge s_axi_aclk) begin
    rst_status_buf[0] <= rst_status;
    rst_status_buf[1] <= rst_status_buf[0];
  end
  
  // Clear signal from AXI write
  wire clear;
  assign clear = (write_state == DATA) && s_axi_wvalid && wready && 
                 (s_axi_awaddr[3:0] == RESET_STATUS_ADDR) && (s_axi_wdata == 32'h0);
  
  // Assign outputs
  assign s_axi_awready = awready;
  assign s_axi_wready = wready;
  assign s_axi_bresp = 2'b00; // OKAY response
  assign s_axi_bvalid = bvalid;
  assign s_axi_arready = arready;
  assign s_axi_rdata = rdata;
  assign s_axi_rresp = 2'b00; // OKAY response
  assign s_axi_rvalid = rvalid;
  
  // Reset status register logic with buffered signals
  // Distribute reset logic to multiple always blocks to reduce combinational path
  reg pwr_rst_buf, pwr_rst_sync;
  reg clear_buf, clear_sync;
  reg aresetn_buf, aresetn_sync;
  
  // Reset synchronization
  always @(posedge s_axi_aclk) begin
    pwr_rst_buf <= pwr_rst;
    pwr_rst_sync <= pwr_rst_buf;
    
    clear_buf <= clear;
    clear_sync <= clear_buf;
    
    aresetn_buf <= s_axi_aresetn;
    aresetn_sync <= aresetn_buf;
  end
  
  // Reset handling divided into separate sequential blocks
  always @(posedge s_axi_aclk or posedge pwr_rst_sync) begin
    if (pwr_rst_sync)
      rst_status[0] <= 1'b1;
    else if (~aresetn_sync)
      rst_status[0] <= 1'b0;
    else if (clear_sync)
      rst_status[0] <= 1'b0;
  end
  
  // WDT reset handling
  reg wdt_rst_buf;
  always @(posedge s_axi_aclk) begin
    wdt_rst_buf <= wdt_rst;
    if (~aresetn_sync)
      rst_status[1] <= 1'b0;
    else if (clear_sync)
      rst_status[1] <= 1'b0;
    else if (wdt_rst_buf)
      rst_status[1] <= 1'b1;
  end
  
  // SW reset handling
  reg sw_rst_buf;
  always @(posedge s_axi_aclk) begin
    sw_rst_buf <= sw_rst;
    if (~aresetn_sync)
      rst_status[2] <= 1'b0;
    else if (clear_sync)
      rst_status[2] <= 1'b0;
    else if (sw_rst_buf)
      rst_status[2] <= 1'b1;
  end
  
  // EXT reset handling
  reg ext_rst_buf;
  always @(posedge s_axi_aclk) begin
    ext_rst_buf <= ext_rst;
    if (~aresetn_sync)
      rst_status[3] <= 1'b0;
    else if (clear_sync)
      rst_status[3] <= 1'b0;
    else if (ext_rst_buf)
      rst_status[3] <= 1'b1;
  end
  
  // Upper bits are always zero
  always @(posedge s_axi_aclk) begin
    if (~aresetn_sync)
      rst_status[7:4] <= 4'b0;
    else if (clear_sync)
      rst_status[7:4] <= 4'b0;
  end
  
  // Write channel state machine with buffered state signals
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (~s_axi_aresetn) begin
      write_state <= IDLE_buf[1];
      awready <= 1'b0;
      wready <= 1'b0;
      bvalid <= 1'b0;
    end else begin
      case (write_state)
        IDLE_buf[1]: begin
          if (s_axi_awvalid) begin
            awready <= 1'b1;
            write_state <= ADDR;
          end
        end
        
        ADDR: begin
          awready <= 1'b0;
          wready <= 1'b1;
          write_state <= DATA;
        end
        
        DATA: begin
          if (s_axi_wvalid) begin
            wready <= 1'b0;
            bvalid <= 1'b1;
            write_state <= RESP;
          end
        end
        
        RESP: begin
          if (s_axi_bready) begin
            bvalid <= 1'b0;
            write_state <= IDLE_buf[1];
          end
        end
      endcase
    end
  end
  
  // Read channel state machine with buffered state signals
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (~s_axi_aresetn) begin
      read_state <= IDLE_buf[0];
      arready <= 1'b0;
      rvalid <= 1'b0;
      rdata <= 32'h0;
    end else begin
      case (read_state)
        IDLE_buf[0]: begin
          if (s_axi_arvalid) begin
            arready <= 1'b1;
            read_state <= ADDR;
          end
        end
        
        ADDR: begin
          arready <= 1'b0;
          
          // Read from the register using buffered status
          if (s_axi_araddr[3:0] == RESET_STATUS_ADDR)
            rdata <= {24'h0, rst_status_buf[1]};
          else
            rdata <= 32'h0;
            
          rvalid <= 1'b1;
          read_state <= DATA;
        end
        
        DATA: begin
          if (s_axi_rready) begin
            rvalid <= 1'b0;
            read_state <= IDLE_buf[0];
          end
        end
        
        default: read_state <= IDLE_buf[0];
      endcase
    end
  end

endmodule