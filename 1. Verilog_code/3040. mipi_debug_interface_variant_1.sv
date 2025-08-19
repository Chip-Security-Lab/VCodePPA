//SystemVerilog
module mipi_debug_interface (
  // Global signals
  input wire ACLK,
  input wire ARESETn,
  
  // Write Address Channel
  input wire [31:0] AWADDR,
  input wire AWVALID,
  output reg AWREADY,
  
  // Write Data Channel
  input wire [31:0] WDATA,
  input wire [3:0] WSTRB,
  input wire WVALID,
  output reg WREADY,
  
  // Write Response Channel
  output reg [1:0] BRESP,
  output reg BVALID,
  input wire BREADY,
  
  // Read Address Channel
  input wire [31:0] ARADDR,
  input wire ARVALID,
  output reg ARREADY,
  
  // Read Data Channel
  output reg [31:0] RDATA,
  output reg [1:0] RRESP,
  output reg RVALID,
  input wire RREADY
);

  localparam RESP_OK = 2'b00, RESP_ERROR = 2'b01, RESP_BUSY = 2'b10;
  
  reg [31:0] status_reg;
  reg [31:0] debug_regs [0:15];
  reg [1:0] state;
  reg addr_valid;
  
  integer i;
  
  // State definitions
  localparam IDLE = 2'd0;
  localparam WRITE = 2'd1;
  localparam READ = 2'd2;
  
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state <= IDLE;
      status_reg <= 32'h0000_0001;
      addr_valid <= 1'b0;
      
      // AXI signals
      AWREADY <= 1'b0;
      WREADY <= 1'b0;
      BVALID <= 1'b0;
      ARREADY <= 1'b0;
      RVALID <= 1'b0;
      
      for (i = 0; i < 16; i = i + 1)
        debug_regs[i] <= 32'h0;
    end else begin
      case (state)
        IDLE: begin
          AWREADY <= 1'b1;
          ARREADY <= 1'b1;
          
          if (AWVALID && AWREADY) begin
            state <= WRITE;
            AWREADY <= 1'b0;
            addr_valid <= (AWADDR[31:28] == 4'h0);
          end else if (ARVALID && ARREADY) begin
            state <= READ;
            ARREADY <= 1'b0;
            addr_valid <= (ARADDR[31:28] == 4'h0);
          end
        end
        
        WRITE: begin
          WREADY <= 1'b1;
          if (WVALID && WREADY) begin
            if (addr_valid) begin
              debug_regs[AWADDR[3:0]] <= WDATA;
              BRESP <= RESP_OK;
            end else begin
              BRESP <= RESP_ERROR;
            end
            BVALID <= 1'b1;
            WREADY <= 1'b0;
            state <= IDLE;
          end
        end
        
        READ: begin
          if (addr_valid) begin
            RDATA <= debug_regs[ARADDR[3:0]];
            RRESP <= RESP_OK;
          end else if (ARADDR == 32'hFFFF_FFF0) begin
            RDATA <= status_reg;
            RRESP <= RESP_OK;
          end else begin
            RRESP <= RESP_ERROR;
          end
          RVALID <= 1'b1;
          state <= IDLE;
        end
      endcase
      
      // Response handshaking
      if (BVALID && BREADY) begin
        BVALID <= 1'b0;
      end
      
      if (RVALID && RREADY) begin
        RVALID <= 1'b0;
      end
    end
  end
endmodule