//SystemVerilog
//IEEE 1364-2005 Verilog standard
module masked_priority_arbiter (
  input wire clk,                       // Clock
  input wire rst_n,                     // Active low reset
  
  // AXI4-Lite Slave Interface
  // Write Address Channel
  input wire [31:0] s_axi_awaddr,       // Write address
  input wire s_axi_awvalid,             // Write address valid
  output reg s_axi_awready,             // Write address ready
  
  // Write Data Channel
  input wire [31:0] s_axi_wdata,        // Write data
  input wire [3:0] s_axi_wstrb,         // Write strobes
  input wire s_axi_wvalid,              // Write valid
  output reg s_axi_wready,              // Write ready
  
  // Write Response Channel
  output reg [1:0] s_axi_bresp,         // Write response
  output reg s_axi_bvalid,              // Write response valid
  input wire s_axi_bready,              // Response ready
  
  // Read Address Channel
  input wire [31:0] s_axi_araddr,       // Read address
  input wire s_axi_arvalid,             // Read address valid
  output reg s_axi_arready,             // Read address ready
  
  // Read Data Channel
  output reg [31:0] s_axi_rdata,        // Read data
  output reg [1:0] s_axi_rresp,         // Read response
  output reg s_axi_rvalid,              // Read valid
  input wire s_axi_rready,              // Read ready
  
  // Original output (now internal)
  output wire [3:0] grant               // Grant output
);

  // Internal registers
  reg [3:0] req_reg_stage1;             // Request register (stage 1)
  reg [3:0] req_reg_stage2;             // Request register (stage 2)
  reg [3:0] mask_reg_stage1;            // Mask register (stage 1)
  reg [3:0] mask_reg_stage2;            // Mask register (stage 2)
  reg [3:0] grant_reg_stage1;           // Grant register (stage 1)
  reg [3:0] grant_reg_stage2;           // Grant register (stage 2)
  reg [3:0] grant_reg_stage3;           // Grant register (stage 3 - output)
  
  wire [3:0] masked_req_stage1;         // Masked request (stage 1)
  reg [3:0] masked_req_stage2;          // Masked request (stage 2)
  reg [3:0] grant_next_stage1;          // Next grant value (stage 1)
  reg [3:0] grant_next_stage2;          // Next grant value (stage 2)
  
  // AXI4-Lite register addresses
  localparam REG_REQ_ADDR   = 4'h0;     // 0x00: Request register
  localparam REG_MASK_ADDR  = 4'h4;     // 0x04: Mask register
  localparam REG_GRANT_ADDR = 4'h8;     // 0x08: Grant register (read-only)
  
  // AXI4-Lite state machine states
  localparam IDLE = 3'b000;
  localparam WADDR = 3'b001;
  localparam WDATA_STAGE1 = 3'b010;
  localparam WDATA_STAGE2 = 3'b011;
  localparam WRESP = 3'b100;
  
  // AXI4-Lite write state machine
  reg [2:0] wstate, wstate_next;
  reg [31:0] awaddr_reg_stage1;
  reg [31:0] awaddr_reg_stage2;
  reg [31:0] wdata_reg_stage1;
  reg [3:0] wstrb_reg_stage1;
  
  // AXI4-Lite read state machine states
  localparam RADDR = 2'b00;
  localparam RDATA_STAGE1 = 2'b01;
  localparam RDATA_STAGE2 = 2'b10;
  
  // AXI4-Lite read state machine
  reg [1:0] rstate, rstate_next;
  reg [31:0] araddr_reg_stage1;
  reg [31:0] araddr_reg_stage2;
  
  // AXI response codes
  localparam RESP_OKAY = 2'b00;
  localparam RESP_ERROR = 2'b10;
  
  // Stage 1: Calculate masked request
  assign masked_req_stage1 = req_reg_stage1 & ~mask_reg_stage1;
  
  // Assign the grant output to the final pipeline stage
  assign grant = grant_reg_stage3;
  
  // Pipeline stage 1: Mask requests
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      masked_req_stage2 <= 4'h0;
    end else begin
      masked_req_stage2 <= masked_req_stage1;
    end
  end
  
  // Pipeline stage 2: Generate next grant value
  always @(*) begin
    grant_next_stage1 = 4'h0;
    if (masked_req_stage2[0]) 
      grant_next_stage1[0] = 1'b1;
    else if (masked_req_stage2[1]) 
      grant_next_stage1[1] = 1'b1;
    else if (masked_req_stage2[2]) 
      grant_next_stage1[2] = 1'b1;
    else if (masked_req_stage2[3]) 
      grant_next_stage1[3] = 1'b1;
  end
  
  // Pipeline the grant calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_next_stage2 <= 4'h0;
    end else begin
      grant_next_stage2 <= grant_next_stage1;
    end
  end
  
  // AXI4-Lite write state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wstate <= IDLE;
      awaddr_reg_stage1 <= 32'h0;
      awaddr_reg_stage2 <= 32'h0;
      wdata_reg_stage1 <= 32'h0;
      wstrb_reg_stage1 <= 4'h0;
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= RESP_OKAY;
      req_reg_stage1 <= 4'h0;
      req_reg_stage2 <= 4'h0;
      mask_reg_stage1 <= 4'h0;
      mask_reg_stage2 <= 4'h0;
    end
    else begin
      // Pipeline the register values
      req_reg_stage2 <= req_reg_stage1;
      mask_reg_stage2 <= mask_reg_stage1;
      
      case (wstate)
        IDLE: begin
          s_axi_bresp <= RESP_OKAY;
          
          if (s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
            awaddr_reg_stage1 <= s_axi_awaddr;
            wstate <= WADDR;
          end
        end
        
        WADDR: begin
          s_axi_awready <= 1'b0;
          
          if (s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
            wdata_reg_stage1 <= s_axi_wdata;
            wstrb_reg_stage1 <= s_axi_wstrb;
            awaddr_reg_stage2 <= awaddr_reg_stage1;
            wstate <= WDATA_STAGE1;
          end
        end
        
        WDATA_STAGE1: begin
          s_axi_wready <= 1'b0;
          wstate <= WDATA_STAGE2;
        end
        
        WDATA_STAGE2: begin
          // Handle register writes
          case (awaddr_reg_stage2[3:0])
            REG_REQ_ADDR: begin
              if (wstrb_reg_stage1[0]) req_reg_stage1 <= wdata_reg_stage1[3:0];
            end
            
            REG_MASK_ADDR: begin
              if (wstrb_reg_stage1[0]) mask_reg_stage1 <= wdata_reg_stage1[3:0];
            end
            
            default: begin
              s_axi_bresp <= RESP_ERROR;
            end
          endcase
          
          s_axi_bvalid <= 1'b1;
          wstate <= WRESP;
        end
        
        WRESP: begin
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            wstate <= IDLE;
          end
        end
        
        default: wstate <= IDLE;
      endcase
    end
  end
  
  // AXI4-Lite read state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rstate <= RADDR;
      araddr_reg_stage1 <= 32'h0;
      araddr_reg_stage2 <= 32'h0;
      s_axi_arready <= 1'b0;
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= RESP_OKAY;
      s_axi_rdata <= 32'h0;
    end
    else begin
      case (rstate)
        RADDR: begin
          s_axi_rresp <= RESP_OKAY;
          
          if (s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
            araddr_reg_stage1 <= s_axi_araddr;
            rstate <= RDATA_STAGE1;
          end
        end
        
        RDATA_STAGE1: begin
          s_axi_arready <= 1'b0;
          araddr_reg_stage2 <= araddr_reg_stage1;
          rstate <= RDATA_STAGE2;
        end
        
        RDATA_STAGE2: begin
          s_axi_rvalid <= 1'b1;
          
          // Handle register reads
          case (araddr_reg_stage2[3:0])
            REG_REQ_ADDR: begin
              s_axi_rdata <= {28'h0, req_reg_stage2};
            end
            
            REG_MASK_ADDR: begin
              s_axi_rdata <= {28'h0, mask_reg_stage2};
            end
            
            REG_GRANT_ADDR: begin
              s_axi_rdata <= {28'h0, grant_reg_stage3};
            end
            
            default: begin
              s_axi_rdata <= 32'h0;
              s_axi_rresp <= RESP_ERROR;
            end
          endcase
          
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            rstate <= RADDR;
          end
        end
        
        default: rstate <= RADDR;
      endcase
    end
  end
  
  // Pipeline the grant output through three stages
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_reg_stage1 <= 4'h0;
      grant_reg_stage2 <= 4'h0;
      grant_reg_stage3 <= 4'h0;
    end
    else begin
      grant_reg_stage1 <= grant_next_stage1;
      grant_reg_stage2 <= grant_reg_stage1;
      grant_reg_stage3 <= grant_next_stage2;
    end
  end
  
endmodule