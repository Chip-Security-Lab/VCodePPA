//SystemVerilog
module reset_stability_monitor (
  // Clock and Reset
  input wire                        s_axi_aclk,
  input wire                        s_axi_aresetn,
  
  // AXI4-Lite Write Address Channel
  input wire [31:0]                 s_axi_awaddr,
  input wire [2:0]                  s_axi_awprot,
  input wire                        s_axi_awvalid,
  output reg                        s_axi_awready,
  
  // AXI4-Lite Write Data Channel
  input wire [31:0]                 s_axi_wdata,
  input wire [3:0]                  s_axi_wstrb,
  input wire                        s_axi_wvalid,
  output reg                        s_axi_wready,
  
  // AXI4-Lite Write Response Channel
  output reg [1:0]                  s_axi_bresp,
  output reg                        s_axi_bvalid,
  input wire                        s_axi_bready,
  
  // AXI4-Lite Read Address Channel
  input wire [31:0]                 s_axi_araddr,
  input wire [2:0]                  s_axi_arprot,
  input wire                        s_axi_arvalid,
  output reg                        s_axi_arready,
  
  // AXI4-Lite Read Data Channel
  output reg [31:0]                 s_axi_rdata,
  output reg [1:0]                  s_axi_rresp,
  output reg                        s_axi_rvalid,
  input wire                        s_axi_rready,
  
  // Original reset input for monitoring
  input wire                        reset_n_input,
  
  // Reset stability status output
  output wire                       reset_unstable
);

  // Memory mapped registers
  localparam REG_STATUS       = 4'h0;  // Status register (read-only)
  localparam REG_THRESHOLD    = 4'h4;  // Threshold register (read-write)
  localparam REG_COUNTER      = 4'h8;  // Current counter value (read-only)
  localparam REG_CONTROL      = 4'hC;  // Control register (read-write)
  
  // Core logic registers
  reg                         reset_prev_stage1;
  reg                         edge_detected_stage1;
  reg [3:0]                   glitch_counter_stage2;
  reg                         edge_detected_stage2;
  reg                         threshold_exceeded_stage3;
  reg                         valid_stage1, valid_stage2, valid_stage3;
  
  // Configuration registers
  reg [3:0]                   threshold_value;
  reg                         module_enable;
  reg                         counter_reset;
  reg                         reset_unstable_reg;
  
  // AXI4-Lite interface internal registers
  reg                         write_address_valid;
  reg [31:0]                  write_address;
  reg                         write_data_valid;
  reg [31:0]                  write_data;
  reg [3:0]                   write_strobe;
  reg                         read_address_valid;
  reg [31:0]                  read_address;
  
  // Write address channel handler
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      write_address_valid <= 1'b0;
      write_address <= 32'h0;
    end else begin
      if (s_axi_awvalid && !write_address_valid && !s_axi_awready) begin
        write_address <= s_axi_awaddr;
        write_address_valid <= 1'b1;
        s_axi_awready <= 1'b1;
      end else begin
        s_axi_awready <= 1'b0;
        if (s_axi_bready && s_axi_bvalid) begin
          write_address_valid <= 1'b0;
        end
      end
    end
  end
  
  // Write data channel handler
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_wready <= 1'b0;
      write_data_valid <= 1'b0;
      write_data <= 32'h0;
      write_strobe <= 4'h0;
    end else begin
      if (s_axi_wvalid && !write_data_valid && !s_axi_wready) begin
        write_data <= s_axi_wdata;
        write_strobe <= s_axi_wstrb;
        write_data_valid <= 1'b1;
        s_axi_wready <= 1'b1;
      end else begin
        s_axi_wready <= 1'b0;
        if (s_axi_bready && s_axi_bvalid) begin
          write_data_valid <= 1'b0;
        end
      end
    end
  end
  
  // Write response channel handler
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b00;
    end else begin
      if (write_address_valid && write_data_valid && !s_axi_bvalid) begin
        // Process write operation
        case (write_address[3:0])
          REG_THRESHOLD: begin
            if (write_strobe[0]) 
              threshold_value <= write_data[3:0];
            s_axi_bresp <= 2'b00; // OKAY
          end
          
          REG_CONTROL: begin
            if (write_strobe[0]) begin
              module_enable <= write_data[0];
              counter_reset <= write_data[1];
            end
            s_axi_bresp <= 2'b00; // OKAY
          end
          
          default: begin
            // Write to read-only or undefined register
            s_axi_bresp <= 2'b10; // SLVERR
          end
        endcase
        
        s_axi_bvalid <= 1'b1;
      end else if (s_axi_bready && s_axi_bvalid) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end
  
  // Read address channel handler
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      read_address_valid <= 1'b0;
      read_address <= 32'h0;
    end else begin
      if (s_axi_arvalid && !read_address_valid && !s_axi_arready) begin
        read_address <= s_axi_araddr;
        read_address_valid <= 1'b1;
        s_axi_arready <= 1'b1;
      end else begin
        s_axi_arready <= 1'b0;
        if (s_axi_rready && s_axi_rvalid) begin
          read_address_valid <= 1'b0;
        end
      end
    end
  end
  
  // Read data channel handler
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= 2'b00;
      s_axi_rdata <= 32'h0;
    end else begin
      if (read_address_valid && !s_axi_rvalid) begin
        // Process read operation
        case (read_address[3:0])
          REG_STATUS: begin
            s_axi_rdata <= {31'h0, reset_unstable_reg};
            s_axi_rresp <= 2'b00; // OKAY
          end
          
          REG_THRESHOLD: begin
            s_axi_rdata <= {28'h0, threshold_value};
            s_axi_rresp <= 2'b00; // OKAY
          end
          
          REG_COUNTER: begin
            s_axi_rdata <= {28'h0, glitch_counter_stage2};
            s_axi_rresp <= 2'b00; // OKAY
          end
          
          REG_CONTROL: begin
            s_axi_rdata <= {30'h0, counter_reset, module_enable};
            s_axi_rresp <= 2'b00; // OKAY
          end
          
          default: begin
            // Undefined register
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b10; // SLVERR
          end
        endcase
        
        s_axi_rvalid <= 1'b1;
      end else if (s_axi_rready && s_axi_rvalid) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end
  
  // Original core logic with some adaptations
  //------------------------------------------------------
  // Stage 1: Edge detection logic
  //------------------------------------------------------
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || !module_enable) begin
      reset_prev_stage1 <= 1'b0;
      edge_detected_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      reset_prev_stage1 <= reset_n_input;
      edge_detected_stage1 <= (reset_n_input != reset_prev_stage1);
      valid_stage1 <= 1'b1; // Always valid after first cycle when enabled
    end
  end
  
  //------------------------------------------------------
  // Stage 2: Counter management logic
  //------------------------------------------------------
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || !module_enable || counter_reset) begin
      glitch_counter_stage2 <= 4'h0;
      edge_detected_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      if (valid_stage1) begin
        if (edge_detected_stage1) begin
          glitch_counter_stage2 <= glitch_counter_stage2 + 1'b1;
        end
        edge_detected_stage2 <= edge_detected_stage1;
        valid_stage2 <= valid_stage1;
      end
    end
  end
  
  //------------------------------------------------------
  // Stage 3: Threshold checking logic
  //------------------------------------------------------
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || !module_enable) begin
      threshold_exceeded_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      if (valid_stage2) begin
        threshold_exceeded_stage3 <= (glitch_counter_stage2 > threshold_value);
        valid_stage3 <= valid_stage2;
      end
    end
  end
  
  //------------------------------------------------------
  // Output stage logic
  //------------------------------------------------------
  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || !module_enable) begin
      reset_unstable_reg <= 1'b0;
    end else if (valid_stage3) begin
      reset_unstable_reg <= threshold_exceeded_stage3;
    end
  end
  
  // Connect to output
  assign reset_unstable = reset_unstable_reg;
  
  // Register default values
  initial begin
    // Core logic registers
    reset_prev_stage1 = 1'b0;
    edge_detected_stage1 = 1'b0;
    glitch_counter_stage2 = 4'h0;
    edge_detected_stage2 = 1'b0;
    threshold_exceeded_stage3 = 1'b0;
    valid_stage1 = 1'b0;
    valid_stage2 = 1'b0;
    valid_stage3 = 1'b0;
    
    // Configuration registers
    threshold_value = 4'd5;  // Default threshold
    module_enable = 1'b1;    // Enabled by default
    counter_reset = 1'b0;
    reset_unstable_reg = 1'b0;
    
    // AXI4-Lite interface internal registers
    write_address_valid = 1'b0;
    write_address = 32'h0;
    write_data_valid = 1'b0;
    write_data = 32'h0;
    write_strobe = 4'h0;
    read_address_valid = 1'b0;
    read_address = 32'h0;
    
    // AXI4-Lite output signals
    s_axi_awready = 1'b0;
    s_axi_wready = 1'b0;
    s_axi_bresp = 2'b00;
    s_axi_bvalid = 1'b0;
    s_axi_arready = 1'b0;
    s_axi_rdata = 32'h0;
    s_axi_rresp = 2'b00;
    s_axi_rvalid = 1'b0;
  end
endmodule