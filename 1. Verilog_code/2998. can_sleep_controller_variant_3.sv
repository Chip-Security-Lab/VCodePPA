//SystemVerilog
module can_sleep_controller(
  input wire                        s_axi_aclk,
  input wire                        s_axi_aresetn,
  // AXI4-Lite slave interface
  // Write address channel
  input wire [31:0]                 s_axi_awaddr,
  input wire                        s_axi_awvalid,
  output reg                        s_axi_awready,
  // Write data channel
  input wire [31:0]                 s_axi_wdata,
  input wire [3:0]                  s_axi_wstrb,
  input wire                        s_axi_wvalid,
  output reg                        s_axi_wready,
  // Write response channel
  output reg [1:0]                  s_axi_bresp,
  output reg                        s_axi_bvalid,
  input wire                        s_axi_bready,
  // Read address channel
  input wire [31:0]                 s_axi_araddr,
  input wire                        s_axi_arvalid,
  output reg                        s_axi_arready,
  // Read data channel
  output reg [31:0]                 s_axi_rdata,
  output reg [1:0]                  s_axi_rresp,
  output reg                        s_axi_rvalid,
  input wire                        s_axi_rready,
  // CAN interface signals
  input wire                        can_rx,
  output reg                        can_sleep_mode,
  output reg                        can_wake_event,
  output reg                        power_down_enable
);

  // Constants
  localparam ADDR_WIDTH = 4;  // 4 registers (16 bytes)
  localparam RESP_OKAY = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  
  // Register map (byte addresses)
  localparam REG_CTRL           = 4'h0;  // Control register
  localparam REG_STATUS         = 4'h4;  // Status register
  localparam REG_TIMEOUT        = 4'h8;  // Timeout value register
  localparam REG_DEBUG          = 4'hC;  // Debug register
  
  // Control register bit positions
  localparam CTRL_SLEEP_REQ_BIT = 0;
  localparam CTRL_WAKE_REQ_BIT  = 1;
  
  // Status register bit positions
  localparam STAT_ACTIVE_BIT        = 0;
  localparam STAT_SLEEP_MODE_BIT    = 1;
  localparam STAT_WAKE_EVENT_BIT    = 2;
  localparam STAT_PWR_DOWN_EN_BIT   = 3;
  localparam STAT_ACTIVITY_TMO_BIT  = 4;
  
  // State definitions
  localparam ACTIVE = 0, LISTEN_ONLY = 1, SLEEP_PENDING = 2, SLEEP = 3, WAKEUP = 4;
  
  // Internal signals
  reg [2:0] state, next_state;
  reg [15:0] timeout_counter;
  wire [15:0] next_counter;
  reg sleep_request, wake_request;
  reg activity_timeout;
  
  // AXI4-Lite interface handling
  reg [31:0] reg_ctrl;
  reg [31:0] reg_status;
  reg [31:0] reg_timeout;
  reg [31:0] reg_debug;
  
  reg aw_handled;
  reg w_handled;
  reg ar_handled;
  
  // Skip-carry adder for counter
  skip_carry_adder #(
    .WIDTH(16)
  ) counter_adder (
    .a(timeout_counter),
    .b(16'd1),
    .sum(next_counter)
  );
  
  // Read transactions FSM
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b1;
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= RESP_OKAY;
      ar_handled <= 1'b0;
    end else begin
      // Handle read address
      if (s_axi_arvalid && s_axi_arready) begin
        s_axi_arready <= 1'b0;
        ar_handled <= 1'b1;
        
        // Prepare read data
        case (s_axi_araddr[ADDR_WIDTH-1:0])
          REG_CTRL: s_axi_rdata <= reg_ctrl;
          REG_STATUS: s_axi_rdata <= reg_status;
          REG_TIMEOUT: s_axi_rdata <= reg_timeout;
          REG_DEBUG: s_axi_rdata <= reg_debug;
          default: begin
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= RESP_SLVERR;
          end
        endcase
        
        s_axi_rvalid <= 1'b1;
      end
      
      // Handle read data
      if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
        s_axi_arready <= 1'b1;
        ar_handled <= 1'b0;
      end
    end
  end
  
  // Write transactions FSM
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b1;
      s_axi_wready <= 1'b1;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= RESP_OKAY;
      aw_handled <= 1'b0;
      w_handled <= 1'b0;
      
      // Reset internal registers
      reg_ctrl <= 32'h0;
      reg_timeout <= 32'h0;
      reg_debug <= 32'h0;
    end else begin
      // Handle write address
      if (s_axi_awvalid && s_axi_awready) begin
        s_axi_awready <= 1'b0;
        aw_handled <= 1'b1;
      end
      
      // Handle write data
      if (s_axi_wvalid && s_axi_wready) begin
        s_axi_wready <= 1'b0;
        w_handled <= 1'b1;
        
        // Only write when both address and data are valid
        if (aw_handled) begin
          case (s_axi_awaddr[ADDR_WIDTH-1:0])
            REG_CTRL: begin
              if (s_axi_wstrb[0]) reg_ctrl[7:0] <= s_axi_wdata[7:0];
              if (s_axi_wstrb[1]) reg_ctrl[15:8] <= s_axi_wdata[15:8];
              if (s_axi_wstrb[2]) reg_ctrl[23:16] <= s_axi_wdata[23:16];
              if (s_axi_wstrb[3]) reg_ctrl[31:24] <= s_axi_wdata[31:24];
            end
            REG_TIMEOUT: begin
              if (s_axi_wstrb[0]) reg_timeout[7:0] <= s_axi_wdata[7:0];
              if (s_axi_wstrb[1]) reg_timeout[15:8] <= s_axi_wdata[15:8];
              if (s_axi_wstrb[2]) reg_timeout[23:16] <= s_axi_wdata[23:16];
              if (s_axi_wstrb[3]) reg_timeout[31:24] <= s_axi_wdata[31:24];
            end
            REG_DEBUG: begin
              if (s_axi_wstrb[0]) reg_debug[7:0] <= s_axi_wdata[7:0];
              if (s_axi_wstrb[1]) reg_debug[15:8] <= s_axi_wdata[15:8];
              if (s_axi_wstrb[2]) reg_debug[23:16] <= s_axi_wdata[23:16];
              if (s_axi_wstrb[3]) reg_debug[31:24] <= s_axi_wdata[31:24];
            end
            default: s_axi_bresp <= RESP_SLVERR;
          endcase
        end
      end
      
      // Generate write response
      if (aw_handled && w_handled && !s_axi_bvalid) begin
        s_axi_bvalid <= 1'b1;
      end
      
      // Handle write response
      if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
        s_axi_awready <= 1'b1;
        s_axi_wready <= 1'b1;
        aw_handled <= 1'b0;
        w_handled <= 1'b0;
      end
    end
  end
  
  // Extract control signals from registers
  always @(*) begin
    sleep_request = reg_ctrl[CTRL_SLEEP_REQ_BIT];
    wake_request = reg_ctrl[CTRL_WAKE_REQ_BIT];
    activity_timeout = reg_status[STAT_ACTIVITY_TMO_BIT];
  end
  
  // Update status register
  always @(posedge s_axi_aclk) begin
    reg_status[STAT_ACTIVE_BIT] <= (state == ACTIVE) ? 1'b1 : 1'b0;
    reg_status[STAT_SLEEP_MODE_BIT] <= can_sleep_mode;
    reg_status[STAT_WAKE_EVENT_BIT] <= can_wake_event;
    reg_status[STAT_PWR_DOWN_EN_BIT] <= power_down_enable;
  end
  
  // CAN sleep controller logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      state <= ACTIVE;
      next_state <= ACTIVE;
      can_sleep_mode <= 0;
      can_wake_event <= 0;
      power_down_enable <= 0;
      timeout_counter <= 0;
    end else begin
      state <= next_state;
      
      case (state)
        ACTIVE: begin
          can_sleep_mode <= 0;
          power_down_enable <= 0;
          if (sleep_request)
            next_state <= SLEEP_PENDING;
          else
            next_state <= ACTIVE;
        end
        SLEEP_PENDING: begin
          timeout_counter <= next_counter;
          if (timeout_counter >= reg_timeout[15:0] || activity_timeout)
            next_state <= SLEEP;
          else
            next_state <= SLEEP_PENDING;
        end
        SLEEP: begin
          can_sleep_mode <= 1;
          power_down_enable <= 1;
          if (wake_request || !can_rx) // Wake on CAN activity (dominant bit)
            next_state <= WAKEUP;
          else
            next_state <= SLEEP;
        end
        WAKEUP: begin
          can_wake_event <= 1;
          can_sleep_mode <= 0;
          power_down_enable <= 0;
          next_state <= ACTIVE;
        end
        default: next_state <= ACTIVE;
      endcase
    end
  end
endmodule

module skip_carry_adder #(
  parameter WIDTH = 16
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output wire [WIDTH-1:0] sum
);
  
  // Group size for skip-carry blocks
  localparam GROUP_SIZE = 4;
  localparam NUM_GROUPS = WIDTH/GROUP_SIZE;
  
  wire [WIDTH:0] carry;
  wire [NUM_GROUPS-1:0] group_propagate;
  
  assign carry[0] = 1'b0;
  
  genvar i, g;
  generate
    // Generate propagate signals for each group
    for (g = 0; g < NUM_GROUPS; g = g + 1) begin: gen_group_propagate
      wire [GROUP_SIZE-1:0] p;
      
      for (i = 0; i < GROUP_SIZE; i = i + 1) begin: gen_propagate
        assign p[i] = a[g*GROUP_SIZE+i] | b[g*GROUP_SIZE+i];
      end
      
      assign group_propagate[g] = &p;
    end
    
    // Generate carry and sum for each bit
    for (g = 0; g < NUM_GROUPS; g = g + 1) begin: gen_group
      wire group_cin, group_cout;
      wire [GROUP_SIZE:0] internal_carry;
      
      assign group_cin = carry[g*GROUP_SIZE];
      assign internal_carry[0] = group_cin;
      
      for (i = 0; i < GROUP_SIZE; i = i + 1) begin: gen_bit
        wire p, g_bit;
        
        assign p = a[g*GROUP_SIZE+i] ^ b[g*GROUP_SIZE+i];
        assign g_bit = a[g*GROUP_SIZE+i] & b[g*GROUP_SIZE+i];
        
        assign sum[g*GROUP_SIZE+i] = p ^ internal_carry[i];
        assign internal_carry[i+1] = g_bit | (p & internal_carry[i]);
      end
      
      // Skip carry logic
      assign group_cout = group_propagate[g] ? group_cin : internal_carry[GROUP_SIZE];
      assign carry[g*GROUP_SIZE+GROUP_SIZE] = group_cout;
    end
  endgenerate
endmodule