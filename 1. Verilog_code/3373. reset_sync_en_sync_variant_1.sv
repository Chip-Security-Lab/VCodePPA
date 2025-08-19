//SystemVerilog
//IEEE 1364-2005 Verilog

// AXI4-Lite Reset Synchronizer Top Module
module reset_sync_en_sync(
  // Clock and global reset
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // AXI4-Lite Write Address Channel
  input  wire [31:0] s_axi_awaddr,
  input  wire [2:0]  s_axi_awprot,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  
  // AXI4-Lite Write Data Channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  
  // AXI4-Lite Write Response Channel
  output wire [1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // AXI4-Lite Read Address Channel
  input  wire [31:0] s_axi_araddr,
  input  wire [2:0]  s_axi_arprot,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  
  // AXI4-Lite Read Data Channel
  output wire [31:0] s_axi_rdata,
  output wire [1:0]  s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // Reset sync output
  output wire        rst_sync
);

  // Register Addresses
  localparam ADDR_CONTROL = 4'h0;  // Control register address offset
  localparam ADDR_STATUS  = 4'h4;  // Status register address offset
  
  // Register bit definitions
  localparam BIT_EN     = 0;  // Enable bit position
  localparam BIT_RST_N  = 1;  // Reset bit position

  // Internal signals
  wire [3:0]  addr_reg;
  wire        en_reg;
  wire        rst_n_reg;
  
  // Instantiate write control module
  axi_write_controller write_ctrl (
    .clk(s_axi_aclk),
    .rst_n(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr[3:0]),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .addr_reg(addr_reg),
    .en_reg(en_reg),
    .rst_n_reg(rst_n_reg),
    .ADDR_CONTROL(ADDR_CONTROL),
    .BIT_EN(BIT_EN),
    .BIT_RST_N(BIT_RST_N)
  );
  
  // Instantiate read control module
  axi_read_controller read_ctrl (
    .clk(s_axi_aclk),
    .rst_n(s_axi_aresetn),
    .s_axi_araddr(s_axi_araddr[3:0]), 
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .rst_sync(rst_sync),
    .en_reg(en_reg),
    .rst_n_reg(rst_n_reg),
    .ADDR_CONTROL(ADDR_CONTROL),
    .ADDR_STATUS(ADDR_STATUS)
  );
  
  // Instantiate reset synchronizer module
  reset_synchronizer sync_core (
    .clk(s_axi_aclk),
    .rst_n_reg(rst_n_reg),
    .en_reg(en_reg),
    .rst_sync(rst_sync)
  );

endmodule

// AXI4-Lite Write Controller Module
module axi_write_controller (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [3:0]  s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,
  output reg  [1:0]  s_axi_bresp,
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,
  output reg  [3:0]  addr_reg,
  output reg         en_reg,
  output reg         rst_n_reg,
  input  wire [3:0]  ADDR_CONTROL,
  input  wire        BIT_EN,
  input  wire        BIT_RST_N
);

  // AXI4-Lite Write FSM States
  localparam STATE_IDLE       = 2'b00;
  localparam STATE_WRITE_ADDR = 2'b01;
  localparam STATE_WRITE_DATA = 2'b10;

  reg [1:0] write_state;

  // Initialize FSM and output signals
  initial begin
    s_axi_awready = 1'b0;
    s_axi_wready  = 1'b0;
    s_axi_bvalid  = 1'b0;
    s_axi_bresp   = 2'b00;
    write_state   = STATE_IDLE;
    en_reg        = 1'b0;
    rst_n_reg     = 1'b0;
    addr_reg      = 4'b0;
  end

  // Write state machine
  always @(posedge clk) begin
    if (!rst_n) begin
      write_state   <= STATE_IDLE;
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      en_reg        <= 1'b0;
      rst_n_reg     <= 1'b0;
      addr_reg      <= 4'b0;
    end else begin
      case (write_state)
        STATE_IDLE: begin
          if (s_axi_awvalid) begin
            addr_reg      <= s_axi_awaddr;
            s_axi_awready <= 1'b1;
            write_state   <= STATE_WRITE_ADDR;
          end
        end
        
        STATE_WRITE_ADDR: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            s_axi_wready  <= 1'b1;
            write_state   <= STATE_WRITE_DATA;
            
            // Handle register writes
            if (addr_reg == ADDR_CONTROL) begin
              if (s_axi_wstrb[0]) begin
                en_reg    <= s_axi_wdata[BIT_EN];
                rst_n_reg <= s_axi_wdata[BIT_RST_N];
              end
            end
          end
        end
        
        STATE_WRITE_DATA: begin
          s_axi_wready  <= 1'b0;
          s_axi_bvalid  <= 1'b1;
          s_axi_bresp   <= 2'b00;  // OKAY response
          
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            write_state  <= STATE_IDLE;
          end
        end
        
        default: write_state <= STATE_IDLE;
      endcase
    end
  end
endmodule

// AXI4-Lite Read Controller Module
module axi_read_controller (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [3:0]  s_axi_araddr,
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,
  output reg  [31:0] s_axi_rdata,
  output reg  [1:0]  s_axi_rresp,
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready,
  input  wire        rst_sync,
  input  wire        en_reg,
  input  wire        rst_n_reg,
  input  wire [3:0]  ADDR_CONTROL,
  input  wire [3:0]  ADDR_STATUS
);

  // AXI4-Lite Read FSM States
  localparam STATE_IDLE      = 2'b00;
  localparam STATE_READ_ADDR = 2'b01;
  
  reg [1:0] read_state;
  reg [3:0] addr_reg;

  // Initialize FSM and output signals
  initial begin
    s_axi_arready = 1'b0;
    s_axi_rvalid  = 1'b0;
    s_axi_rresp   = 2'b00;
    s_axi_rdata   = 32'b0;
    read_state    = STATE_IDLE;
    addr_reg      = 4'b0;
  end

  // Read state machine
  always @(posedge clk) begin
    if (!rst_n) begin
      read_state    <= STATE_IDLE;
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rresp   <= 2'b00;
      s_axi_rdata   <= 32'b0;
      addr_reg      <= 4'b0;
    end else begin
      case (read_state)
        STATE_IDLE: begin
          if (s_axi_arvalid) begin
            addr_reg      <= s_axi_araddr;
            s_axi_arready <= 1'b1;
            read_state    <= STATE_READ_ADDR;
          end
        end
        
        STATE_READ_ADDR: begin
          s_axi_arready <= 1'b0;
          s_axi_rvalid  <= 1'b1;
          s_axi_rresp   <= 2'b00;  // OKAY response
          
          // Prepare read data based on address
          case (addr_reg)
            ADDR_CONTROL: s_axi_rdata <= {30'b0, rst_n_reg, en_reg};
            ADDR_STATUS:  s_axi_rdata <= {31'b0, rst_sync};
            default:      s_axi_rdata <= 32'b0;
          endcase
          
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            read_state   <= STATE_IDLE;
          end
        end
        
        default: read_state <= STATE_IDLE;
      endcase
    end
  end
endmodule

// Reset Synchronizer Core Module
module reset_synchronizer (
  input  wire  clk,
  input  wire  rst_n_reg,
  input  wire  en_reg,
  output reg   rst_sync
);

  reg stage;

  // Initialize output signals
  initial begin
    stage    = 1'b0;
    rst_sync = 1'b0;
  end

  // Core reset synchronization logic
  always @(posedge clk) begin
    if (!rst_n_reg) begin
      stage    <= 1'b0;
      rst_sync <= 1'b0;
    end else if (en_reg) begin
      stage    <= 1'b1;
      rst_sync <= stage;
    end
  end
endmodule