//SystemVerilog
module can_message_filter (
  // Global signals
  input wire aclk,
  input wire aresetn,
  
  // AXI4-Lite Slave interface
  // Write Address Channel
  input wire [7:0] s_axil_awaddr,
  input wire s_axil_awvalid,
  output reg s_axil_awready,
  
  // Write Data Channel
  input wire [31:0] s_axil_wdata,
  input wire [3:0] s_axil_wstrb,
  input wire s_axil_wvalid,
  output reg s_axil_wready,
  
  // Write Response Channel
  output reg [1:0] s_axil_bresp,
  output reg s_axil_bvalid,
  input wire s_axil_bready,
  
  // Read Address Channel
  input wire [7:0] s_axil_araddr,
  input wire s_axil_arvalid,
  output reg s_axil_arready,
  
  // Read Data Channel
  output reg [31:0] s_axil_rdata,
  output reg [1:0] s_axil_rresp,
  output reg s_axil_rvalid,
  input wire s_axil_rready,
  
  // CAN Signals
  input wire [10:0] rx_id,
  input wire id_valid,
  output reg frame_accepted
);

  // Internal registers
  reg [10:0] filter_masks [0:3];
  reg [10:0] filter_values [0:3];
  reg [3:0] filter_enable;
  reg [3:0] match;
  
  // Status register
  reg [31:0] status_reg;
  
  // AXI4-Lite FSM states
  localparam IDLE = 2'b00;
  localparam WRITE = 2'b01;
  localparam READ = 2'b10;
  localparam RESP = 2'b11;
  
  reg [1:0] write_state;
  reg [1:0] read_state;
  reg [7:0] write_addr;
  reg [7:0] read_addr;
  
  // Register address map
  localparam CTRL_REG_ADDR      = 8'h00; // Control register (filter_enable)
  localparam MASK0_REG_ADDR     = 8'h04; // Filter mask 0
  localparam MASK1_REG_ADDR     = 8'h08; // Filter mask 1
  localparam MASK2_REG_ADDR     = 8'h0C; // Filter mask 2
  localparam MASK3_REG_ADDR     = 8'h10; // Filter mask 3
  localparam VALUE0_REG_ADDR    = 8'h14; // Filter value 0
  localparam VALUE1_REG_ADDR    = 8'h18; // Filter value 1
  localparam VALUE2_REG_ADDR    = 8'h1C; // Filter value 2
  localparam VALUE3_REG_ADDR    = 8'h20; // Filter value 3
  localparam STATUS_REG_ADDR    = 8'h24; // Status register
  
  integer i;
  
  // Write channel FSM
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_state <= IDLE;
      s_axil_awready <= 1'b0;
      s_axil_wready <= 1'b0;
      s_axil_bvalid <= 1'b0;
      s_axil_bresp <= 2'b00;
      filter_enable <= 4'b0000;
      
      for (i = 0; i < 4; i = i + 1) begin
        filter_masks[i] <= 11'h0;
        filter_values[i] <= 11'h0;
      end
      
    end else begin
      case (write_state)
        IDLE: begin
          s_axil_bresp <= 2'b00; // OKAY response
          
          if (s_axil_awvalid && s_axil_wvalid) begin
            write_addr <= s_axil_awaddr;
            s_axil_awready <= 1'b1;
            s_axil_wready <= 1'b1;
            write_state <= WRITE;
          end
        end
        
        WRITE: begin
          s_axil_awready <= 1'b0;
          s_axil_wready <= 1'b0;
          
          // Process register writes
          case (write_addr)
            CTRL_REG_ADDR: begin
              if (s_axil_wstrb[0])
                filter_enable <= s_axil_wdata[3:0];
            end
            
            MASK0_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_masks[0] <= s_axil_wdata[10:0];
            end
            
            MASK1_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_masks[1] <= s_axil_wdata[10:0];
            end
            
            MASK2_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_masks[2] <= s_axil_wdata[10:0];
            end
            
            MASK3_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_masks[3] <= s_axil_wdata[10:0];
            end
            
            VALUE0_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_values[0] <= s_axil_wdata[10:0];
            end
            
            VALUE1_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_values[1] <= s_axil_wdata[10:0];
            end
            
            VALUE2_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_values[2] <= s_axil_wdata[10:0];
            end
            
            VALUE3_REG_ADDR: begin
              if (s_axil_wstrb[0] && s_axil_wstrb[1])
                filter_values[3] <= s_axil_wdata[10:0];
            end
            
            default: begin
              s_axil_bresp <= 2'b10; // SLVERR response for invalid address
            end
          endcase
          
          s_axil_bvalid <= 1'b1;
          write_state <= RESP;
        end
        
        RESP: begin
          if (s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
            write_state <= IDLE;
          end
        end
        
        default: write_state <= IDLE;
      endcase
    end
  end
  
  // Read channel FSM
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      read_state <= IDLE;
      s_axil_arready <= 1'b0;
      s_axil_rvalid <= 1'b0;
      s_axil_rresp <= 2'b00;
      s_axil_rdata <= 32'h0;
    end else begin
      case (read_state)
        IDLE: begin
          s_axil_rresp <= 2'b00; // OKAY response
          
          if (s_axil_arvalid) begin
            read_addr <= s_axil_araddr;
            s_axil_arready <= 1'b1;
            read_state <= READ;
          end
        end
        
        READ: begin
          s_axil_arready <= 1'b0;
          
          // Process register reads
          case (read_addr)
            CTRL_REG_ADDR: begin
              s_axil_rdata <= {28'h0, filter_enable};
            end
            
            MASK0_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_masks[0]};
            end
            
            MASK1_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_masks[1]};
            end
            
            MASK2_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_masks[2]};
            end
            
            MASK3_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_masks[3]};
            end
            
            VALUE0_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_values[0]};
            end
            
            VALUE1_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_values[1]};
            end
            
            VALUE2_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_values[2]};
            end
            
            VALUE3_REG_ADDR: begin
              s_axil_rdata <= {21'h0, filter_values[3]};
            end
            
            STATUS_REG_ADDR: begin
              s_axil_rdata <= {27'h0, frame_accepted, match};
            end
            
            default: begin
              s_axil_rdata <= 32'h0;
              s_axil_rresp <= 2'b10; // SLVERR response for invalid address
            end
          endcase
          
          s_axil_rvalid <= 1'b1;
          read_state <= RESP;
        end
        
        RESP: begin
          if (s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
            read_state <= IDLE;
          end
        end
        
        default: read_state <= IDLE;
      endcase
    end
  end
  
  // Core CAN message filtering logic - maintained from original design
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      frame_accepted <= 1'b0;
      match <= 4'b0000;
    end else if (id_valid) begin
      match <= 4'b0000;
      for (i = 0; i < 4; i = i + 1) begin
        if (filter_enable[i] && ((rx_id & filter_masks[i]) == filter_values[i]))
          match[i] <= 1'b1;
      end
      frame_accepted <= (match != 4'b0000);
    end
  end

endmodule