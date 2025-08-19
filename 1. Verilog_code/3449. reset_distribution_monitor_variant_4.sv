//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_distribution_monitor (
  // Clock and Reset
  input wire aclk,
  input wire aresetn,
  
  // AXI4-Lite Interface - Write Address Channel
  input wire [31:0] s_axil_awaddr,
  input wire s_axil_awvalid,
  output reg s_axil_awready,
  
  // AXI4-Lite Interface - Write Data Channel
  input wire [31:0] s_axil_wdata,
  input wire [3:0] s_axil_wstrb,
  input wire s_axil_wvalid,
  output reg s_axil_wready,
  
  // AXI4-Lite Interface - Write Response Channel
  output reg [1:0] s_axil_bresp,
  output reg s_axil_bvalid,
  input wire s_axil_bready,
  
  // AXI4-Lite Interface - Read Address Channel
  input wire [31:0] s_axil_araddr,
  input wire s_axil_arvalid,
  output reg s_axil_arready,
  
  // AXI4-Lite Interface - Read Data Channel
  output reg [31:0] s_axil_rdata,
  output reg [1:0] s_axil_rresp,
  output reg s_axil_rvalid,
  input wire s_axil_rready,
  
  // Original input signal
  input wire [7:0] local_resets
);

  // Internal registers
  reg [7:0] local_resets_reg;
  reg global_reset_reg;
  reg distribution_error_reg;
  
  // Stage 1: Edge detection and pipeline control
  reg global_reset_d;
  wire reset_edge;
  reg reset_edge_stage1;
  reg reset_valid_stage1;
  
  // Stage 2: State counter management
  reg [2:0] check_state;
  reg reset_edge_stage2;
  reg reset_valid_stage2;
  
  // Stage 3: Error detection
  wire check_complete;
  reg [7:0] local_resets_stage3;
  reg reset_edge_stage3;
  reg reset_valid_stage3;
  
  // Stage 4: Output generation
  wire error_condition;
  
  // Memory-mapped registers addresses
  localparam GLOBAL_RESET_ADDR   = 32'h0000_0000;
  localparam LOCAL_RESETS_ADDR   = 32'h0000_0004;
  localparam ERROR_STATUS_ADDR   = 32'h0000_0008;
  
  // Write address channel logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_awready <= 1'b0;
    end else begin
      if (!s_axil_awready && s_axil_awvalid && s_axil_wvalid) begin
        s_axil_awready <= 1'b1;
      end else begin
        s_axil_awready <= 1'b0;
      end
    end
  end
  
  // Write data channel logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_wready <= 1'b0;
      global_reset_reg <= 1'b0;
    end else begin
      if (!s_axil_wready && s_axil_wvalid && s_axil_awvalid) begin
        s_axil_wready <= 1'b1;
        
        // Process write data
        case (s_axil_awaddr[11:0])
          GLOBAL_RESET_ADDR: begin
            if (s_axil_wstrb[0]) global_reset_reg <= s_axil_wdata[0];
          end
          default: begin
            // No action for other addresses
          end
        endcase
      end else begin
        s_axil_wready <= 1'b0;
      end
    end
  end
  
  // Write response channel logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_bvalid <= 1'b0;
      s_axil_bresp <= 2'b00;
    end else begin
      if (s_axil_awready && s_axil_awvalid && s_axil_wready && s_axil_wvalid && !s_axil_bvalid) begin
        s_axil_bvalid <= 1'b1;
        s_axil_bresp <= 2'b00; // OKAY response
      end else if (s_axil_bvalid && s_axil_bready) begin
        s_axil_bvalid <= 1'b0;
      end
    end
  end
  
  // Read address channel logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_arready <= 1'b0;
    end else begin
      if (!s_axil_arready && s_axil_arvalid) begin
        s_axil_arready <= 1'b1;
      end else begin
        s_axil_arready <= 1'b0;
      end
    end
  end
  
  // Read data channel logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axil_rvalid <= 1'b0;
      s_axil_rresp <= 2'b00;
      s_axil_rdata <= 32'h0000_0000;
    end else begin
      if (s_axil_arready && s_axil_arvalid && !s_axil_rvalid) begin
        s_axil_rvalid <= 1'b1;
        s_axil_rresp <= 2'b00; // OKAY response
        
        // Return register data
        case (s_axil_araddr[11:0])
          GLOBAL_RESET_ADDR: s_axil_rdata <= {31'b0, global_reset_reg};
          LOCAL_RESETS_ADDR: s_axil_rdata <= {24'b0, local_resets};
          ERROR_STATUS_ADDR: s_axil_rdata <= {31'b0, distribution_error_reg};
          default: s_axil_rdata <= 32'h0000_0000;
        endcase
      end else if (s_axil_rvalid && s_axil_rready) begin
        s_axil_rvalid <= 1'b0;
      end
    end
  end
  
  // Core reset monitoring logic
  // Precompute logic for stage 1
  assign reset_edge = global_reset_reg && !global_reset_d;
  
  // Stage 3 logic
  assign check_complete = (check_state == 3'd3);
  
  // Stage 4 logic
  assign error_condition = check_complete && (local_resets_stage3 != 8'hFF);
  
  // Pipeline Stage 1: Edge detection
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      global_reset_d <= 1'b0;
      reset_edge_stage1 <= 1'b0;
      reset_valid_stage1 <= 1'b0;
    end else begin
      global_reset_d <= global_reset_reg;
      reset_edge_stage1 <= reset_edge;
      reset_valid_stage1 <= 1'b1;  // Start pipeline
    end
  end
  
  // Pipeline Stage 2: Counter management
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      reset_edge_stage2 <= 1'b0;
      reset_valid_stage2 <= 1'b0;
      check_state <= 3'd0;
    end else begin
      reset_edge_stage2 <= reset_edge_stage1;
      reset_valid_stage2 <= reset_valid_stage1;
      
      // State counter logic
      if (reset_edge_stage1)
        check_state <= 3'd0;
      else if (check_state < 3'd4)
        check_state <= check_state + 3'd1;
    end
  end
  
  // Pipeline Stage 3: Prepare error detection
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      local_resets_stage3 <= 8'h00;
      reset_edge_stage3 <= 1'b0;
      reset_valid_stage3 <= 1'b0;
    end else begin
      local_resets_stage3 <= local_resets;
      reset_edge_stage3 <= reset_edge_stage2;
      reset_valid_stage3 <= reset_valid_stage2;
    end
  end
  
  // Pipeline Stage 4: Generate output
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      distribution_error_reg <= 1'b0;
    end else begin
      if (reset_valid_stage3) begin
        if (error_condition)
          distribution_error_reg <= 1'b1;
        else if (reset_edge_stage3)
          distribution_error_reg <= 1'b0;
      end
    end
  end
endmodule