//SystemVerilog
module tristate_bus_arbiter (
  // AXI4-Lite Slave Interface
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  // Write Address Channel
  input  wire [7:0]  s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  // Write Data Channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  // Write Response Channel
  output wire [1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  // Read Address Channel
  input  wire [7:0]  s_axi_araddr,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  // Read Data Channel
  output wire [31:0] s_axi_rdata,
  output wire [1:0]  s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // Original arbiter interface
  input  wire [3:0]  req,
  output wire [3:0]  grant,
  inout  wire [7:0]  data_bus,
  input  wire [7:0]  data_in [3:0],
  output wire [7:0]  data_out
);

  // Internal registers
  reg [3:0]  grant_r;
  reg [1:0]  current;
  reg [7:0]  config_reg;
  reg [3:0]  req_override;
  
  // AXI interface registers
  reg        awready_r;
  reg        wready_r;
  reg [1:0]  bresp_r;
  reg        bvalid_r;
  reg        arready_r;
  reg [31:0] rdata_r;
  reg [1:0]  rresp_r;
  reg        rvalid_r;
  
  // Write address states
  localparam WADDR_IDLE = 1'b0;
  localparam WADDR_BUSY = 1'b1;
  reg waddr_state;
  reg [7:0] waddr;
  
  // Write data states
  localparam WDATA_IDLE = 1'b0;
  localparam WDATA_BUSY = 1'b1;
  reg wdata_state;
  reg [31:0] wdata;
  reg [3:0] wstrb;
  
  // Read states
  localparam READ_IDLE = 1'b0;
  localparam READ_BUSY = 1'b1;
  reg read_state;
  reg [7:0] raddr;
  
  // 前向寄存器优化：捕获输入信号
  reg [3:0] req_r;
  reg [7:0] data_in_r [3:0];
  
  // Pre-computed control signals
  wire [3:0] req_actual;
  reg  [3:0] req_actual_r;
  
  // Connect original interface with optimized registers
  assign grant = grant_r;
  assign data_bus = grant_r[0] ? data_in_r[0] : 
                   (grant_r[1] ? data_in_r[1] : 
                   (grant_r[2] ? data_in_r[2] : 
                   (grant_r[3] ? data_in_r[3] : 8'bz)));
  assign data_out = data_bus;
  
  // AXI outputs assignments
  assign s_axi_awready = awready_r;
  assign s_axi_wready = wready_r;
  assign s_axi_bresp = bresp_r;
  assign s_axi_bvalid = bvalid_r;
  assign s_axi_arready = arready_r;
  assign s_axi_rdata = rdata_r;
  assign s_axi_rresp = rresp_r;
  assign s_axi_rvalid = rvalid_r;
  
  // 前向寄存器优化：输入寄存
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      req_r <= 4'h0;
      data_in_r[0] <= 8'h0;
      data_in_r[1] <= 8'h0;
      data_in_r[2] <= 8'h0;
      data_in_r[3] <= 8'h0;
    end else begin
      req_r <= req;
      data_in_r[0] <= data_in[0];
      data_in_r[1] <= data_in[1];
      data_in_r[2] <= data_in[2];
      data_in_r[3] <= data_in[3];
    end
  end
  
  // 前向寄存器优化：将组合逻辑结果寄存
  assign req_actual = config_reg[0] ? req_override : req_r;
  
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      req_actual_r <= 4'h0;
    end else begin
      req_actual_r <= req_actual;
    end
  end

  // Write address channel handling
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      awready_r <= 1'b0;
      waddr_state <= WADDR_IDLE;
      waddr <= 8'h0;
    end else begin
      case (waddr_state)
        WADDR_IDLE: begin
          if (s_axi_awvalid) begin
            awready_r <= 1'b1;
            waddr <= s_axi_awaddr;
            waddr_state <= WADDR_BUSY;
          end
        end
        WADDR_BUSY: begin
          awready_r <= 1'b0;
          if (bvalid_r && s_axi_bready) begin
            waddr_state <= WADDR_IDLE;
          end
        end
      endcase
    end
  end
  
  // Write data channel handling
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      wready_r <= 1'b0;
      wdata_state <= WDATA_IDLE;
      wdata <= 32'h0;
      wstrb <= 4'h0;
      bresp_r <= 2'b00;
      bvalid_r <= 1'b0;
      config_reg <= 8'h0;
      req_override <= 4'h0;
    end else begin
      case (wdata_state)
        WDATA_IDLE: begin
          if (s_axi_wvalid) begin
            wready_r <= 1'b1;
            wdata <= s_axi_wdata;
            wstrb <= s_axi_wstrb;
            wdata_state <= WDATA_BUSY;
            
            // Process write data based on address
            case (waddr)
              8'h00: begin // Configuration register
                if (s_axi_wstrb[0]) config_reg <= s_axi_wdata[7:0];
              end
              8'h04: begin // Request override register
                if (s_axi_wstrb[0]) req_override <= s_axi_wdata[3:0];
              end
              default: begin
                // Invalid address - do nothing
              end
            endcase
            
            // Set response
            bresp_r <= 2'b00; // OKAY response
            bvalid_r <= 1'b1;
          end
        end
        WDATA_BUSY: begin
          wready_r <= 1'b0;
          if (bvalid_r && s_axi_bready) begin
            bvalid_r <= 1'b0;
            wdata_state <= WDATA_IDLE;
          end
        end
      endcase
    end
  end
  
  // Read address channel handling
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      arready_r <= 1'b0;
      read_state <= READ_IDLE;
      raddr <= 8'h0;
      rdata_r <= 32'h0;
      rresp_r <= 2'b00;
      rvalid_r <= 1'b0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          if (s_axi_arvalid) begin
            arready_r <= 1'b1;
            raddr <= s_axi_araddr;
            read_state <= READ_BUSY;
          end
        end
        READ_BUSY: begin
          arready_r <= 1'b0;
          
          // Process read based on address
          case (raddr)
            8'h00: begin // Configuration register
              rdata_r <= {24'h0, config_reg};
            end
            8'h04: begin // Request override register
              rdata_r <= {28'h0, req_override};
            end
            8'h08: begin // Current grant status
              rdata_r <= {28'h0, grant_r};
            end
            8'h0C: begin // Current data output
              rdata_r <= {24'h0, data_out};
            end
            default: begin
              rdata_r <= 32'h0;
            end
          endcase
          
          rresp_r <= 2'b00; // OKAY response
          rvalid_r <= 1'b1;
          
          if (rvalid_r && s_axi_rready) begin
            rvalid_r <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
      endcase
    end
  end
  
  // 优化后的仲裁逻辑：使用已经寄存的信号
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      grant_r <= 4'h0;
      current <= 2'b00;
    end else begin
      if (!config_reg[1]) begin  // Normal mode
        if (req_actual_r[current]) 
          grant_r <= (4'h1 << current);
        else 
          grant_r <= 4'h0;
        current <= current + 1;
      end else begin  // Fixed priority mode
        if (req_actual_r[0])
          grant_r <= 4'h1;
        else if (req_actual_r[1])
          grant_r <= 4'h2;
        else if (req_actual_r[2])
          grant_r <= 4'h4;
        else if (req_actual_r[3])
          grant_r <= 4'h8;
        else
          grant_r <= 4'h0;
      end
    end
  end

endmodule