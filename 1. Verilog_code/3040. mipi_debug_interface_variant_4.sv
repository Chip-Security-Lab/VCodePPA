//SystemVerilog
module mipi_debug_interface (
  // Clock and Reset
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

  localparam RESP_OKAY = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  
  reg [31:0] status_reg;
  reg [31:0] debug_regs [0:15];
  reg [1:0] state;
  
  integer i;
  
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state <= 2'd0;
      AWREADY <= 1'b0;
      WREADY <= 1'b0;
      BVALID <= 1'b0;
      ARREADY <= 1'b0;
      RVALID <= 1'b0;
      BRESP <= RESP_OKAY;
      RRESP <= RESP_OKAY;
      status_reg <= 32'h0000_0001;
      
      for (i = 0; i < 16; i = i + 1)
        debug_regs[i] <= 32'h0;
    end else begin
      case (state)
        2'd0: begin
          AWREADY <= 1'b1;
          ARREADY <= 1'b1;
          if (AWVALID && AWREADY) begin
            AWREADY <= 1'b0;
            state <= 2'd1;
          end else if (ARVALID && ARREADY) begin
            ARREADY <= 1'b0;
            state <= 2'd2;
          end
        end
        
        2'd1: begin
          WREADY <= 1'b1;
          if (WVALID && WREADY) begin
            WREADY <= 1'b0;
            if (AWADDR[31:28] == 4'h0) begin
              debug_regs[AWADDR[3:0]] <= WDATA;
              BRESP <= RESP_OKAY;
            end else begin
              BRESP <= RESP_SLVERR;
            end
            BVALID <= 1'b1;
            state <= 2'd3;
          end
        end
        
        2'd2: begin
          if (ARADDR[31:28] == 4'h0) begin
            RDATA <= debug_regs[ARADDR[3:0]];
            RRESP <= RESP_OKAY;
          end else if (ARADDR == 32'hFFFF_FFF0) begin
            RDATA <= status_reg;
            RRESP <= RESP_OKAY;
          end else begin
            RRESP <= RESP_SLVERR;
          end
          RVALID <= 1'b1;
          state <= 2'd3;
        end
        
        2'd3: begin
          if ((BVALID && BREADY) || (RVALID && RREADY)) begin
            BVALID <= 1'b0;
            RVALID <= 1'b0;
            state <= 2'd0;
          end
        end
      endcase
    end
  end
endmodule