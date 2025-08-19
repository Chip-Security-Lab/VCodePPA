//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module reset_delay_monitor (
  // Clock and Reset
  input  wire        clk,
  input  wire        reset_n,
  
  // AXI4-Lite Slave Interface
  // Write Address Channel
  input  wire        s_axil_awvalid,
  output wire        s_axil_awready,
  input  wire [31:0] s_axil_awaddr,
  input  wire [2:0]  s_axil_awprot,
  
  // Write Data Channel
  input  wire        s_axil_wvalid,
  output wire        s_axil_wready,
  input  wire [31:0] s_axil_wdata,
  input  wire [3:0]  s_axil_wstrb,
  
  // Write Response Channel
  output wire        s_axil_bvalid,
  input  wire        s_axil_bready,
  output wire [1:0]  s_axil_bresp,
  
  // Read Address Channel
  input  wire        s_axil_arvalid,
  output wire        s_axil_arready,
  input  wire [31:0] s_axil_araddr,
  input  wire [2:0]  s_axil_arprot,
  
  // Read Data Channel
  output wire        s_axil_rvalid,
  input  wire        s_axil_rready,
  output wire [31:0] s_axil_rdata,
  output wire [1:0]  s_axil_rresp
);

  // Internal registers
  reg [15:0] delay_counter;
  reg        error_detected;
  reg        error_reported;
  reg        reset_stuck_error;
  
  // Register map
  localparam REG_STATUS_ADDR = 32'h0000_0000;
  localparam RESP_OKAY       = 2'b00;
  localparam RESP_SLVERR     = 2'b10;

  // Error detection logic
  always @(posedge clk) begin
    if (!reset_n) begin
      delay_counter <= delay_counter + 1'b1;
      // Set error flag when maximum delay reached
      if (delay_counter == 16'hFFFE)
        error_detected <= 1'b1;
    end
    else begin
      delay_counter <= 16'h0000;
      error_detected <= 1'b0;
    end
  end

  // Error status update logic
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      reset_stuck_error <= 1'b0;
      error_reported <= 1'b0;
    end
    else if (error_detected && !error_reported) begin
      reset_stuck_error <= 1'b1;
      // Mark error as reported after read or write access
      if ((s_axil_rvalid && s_axil_rready) || 
          (s_axil_bvalid && s_axil_bready))
        error_reported <= 1'b1;
    end
  end

  // AXI4-Lite interface signals
  wire write_transaction_complete;
  wire read_transaction_complete;
  wire valid_write_address;
  wire valid_read_address;
  wire [31:0] read_data;
  
  assign write_transaction_complete = s_axil_bvalid && s_axil_bready;
  assign read_transaction_complete = s_axil_rvalid && s_axil_rready;
  assign valid_write_address = (s_axil_awaddr == REG_STATUS_ADDR);
  assign valid_read_address = (s_axil_araddr == REG_STATUS_ADDR);
  assign read_data = {31'b0, reset_stuck_error};

  // Instantiate AXI-Lite Write Channel Handler
  axil_write_channel_handler write_handler (
    .clk(clk),
    .reset_n(reset_n),
    .awvalid(s_axil_awvalid),
    .awready(s_axil_awready),
    .awaddr(s_axil_awaddr),
    .wvalid(s_axil_wvalid),
    .wready(s_axil_wready),
    .wdata(s_axil_wdata),
    .bvalid(s_axil_bvalid),
    .bready(s_axil_bready),
    .bresp(s_axil_bresp),
    .valid_address(valid_write_address),
    .transaction_complete(write_transaction_complete)
  );

  // Instantiate AXI-Lite Read Channel Handler
  axil_read_channel_handler read_handler (
    .clk(clk),
    .reset_n(reset_n),
    .arvalid(s_axil_arvalid),
    .arready(s_axil_arready),
    .araddr(s_axil_araddr),
    .rvalid(s_axil_rvalid),
    .rready(s_axil_rready),
    .rdata(s_axil_rdata),
    .rresp(s_axil_rresp),
    .valid_address(valid_read_address),
    .read_data(read_data),
    .transaction_complete(read_transaction_complete)
  );

endmodule

//-----------------------------------------------------------------------------
// AXI-Lite Write Channel Handler
//-----------------------------------------------------------------------------
module axil_write_channel_handler (
  input  wire        clk,
  input  wire        reset_n,
  input  wire        awvalid,
  output reg         awready,
  input  wire [31:0] awaddr,
  input  wire        wvalid,
  output reg         wready,
  input  wire [31:0] wdata,
  output reg         bvalid,
  input  wire        bready,
  output reg  [1:0]  bresp,
  input  wire        valid_address,
  input  wire        transaction_complete
);

  // Response codes
  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;

  // AXI4-Lite Write Address Channel
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      awready <= 1'b1;
    end
    else if (awvalid && awready) begin
      awready <= 1'b0;
    end
    else if (transaction_complete) begin
      awready <= 1'b1;
    end
  end

  // AXI4-Lite Write Data Channel
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      wready <= 1'b1;
    end
    else if (wvalid && wready) begin
      wready <= 1'b0;
    end
    else if (transaction_complete) begin
      wready <= 1'b1;
    end
  end

  // AXI4-Lite Write Response Channel
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      bvalid <= 1'b0;
      bresp <= RESP_OKAY;
    end
    else if (awvalid && awready && wvalid && wready) begin
      bvalid <= 1'b1;
      // Check address for valid register
      bresp <= valid_address ? RESP_OKAY : RESP_SLVERR;
    end
    else if (bvalid && bready) begin
      bvalid <= 1'b0;
    end
  end

endmodule

//-----------------------------------------------------------------------------
// AXI-Lite Read Channel Handler
//-----------------------------------------------------------------------------
module axil_read_channel_handler (
  input  wire        clk,
  input  wire        reset_n,
  input  wire        arvalid,
  output reg         arready,
  input  wire [31:0] araddr,
  output reg         rvalid,
  input  wire        rready,
  output reg  [31:0] rdata,
  output reg  [1:0]  rresp,
  input  wire        valid_address,
  input  wire [31:0] read_data,
  input  wire        transaction_complete
);

  // Response codes
  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;

  // AXI4-Lite Read Address Channel
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      arready <= 1'b1;
    end
    else if (arvalid && arready) begin
      arready <= 1'b0;
    end
    else if (transaction_complete) begin
      arready <= 1'b1;
    end
  end

  // AXI4-Lite Read Data Channel
  always @(posedge clk or posedge reset_n) begin
    if (reset_n) begin
      rvalid <= 1'b0;
      rdata <= 32'h0000_0000;
      rresp <= RESP_OKAY;
    end
    else if (arvalid && arready) begin
      rvalid <= 1'b1;
      // Check address for valid register
      if (valid_address) begin
        rdata <= read_data;
        rresp <= RESP_OKAY;
      end
      else begin
        rdata <= 32'h0000_0000;
        rresp <= RESP_SLVERR;
      end
    end
    else if (rvalid && rready) begin
      rvalid <= 1'b0;
    end
  end

endmodule