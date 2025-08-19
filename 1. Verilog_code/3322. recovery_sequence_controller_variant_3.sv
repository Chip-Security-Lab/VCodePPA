//SystemVerilog
module recovery_sequence_controller_axi4lite #(
  parameter AXI_ADDR_WIDTH = 4,
  parameter AXI_DATA_WIDTH = 8
)(
  input  wire                        clk,
  input  wire                        rst_n,
  // AXI4-Lite Slave Interface
  input  wire [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
  input  wire                        s_axi_awvalid,
  output reg                         s_axi_awready,

  input  wire [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
  input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
  input  wire                        s_axi_wvalid,
  output reg                         s_axi_wready,

  output reg [1:0]                   s_axi_bresp,
  output reg                         s_axi_bvalid,
  input  wire                        s_axi_bready,

  input  wire [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
  input  wire                        s_axi_arvalid,
  output reg                         s_axi_arready,

  output reg [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  output reg [1:0]                   s_axi_rresp,
  output reg                         s_axi_rvalid,
  input  wire                        s_axi_rready
);

  // Registers for AXI4-Lite mapped control
  reg        trigger_recovery_reg;
  wire       trigger_recovery;
  assign     trigger_recovery = trigger_recovery_reg;

  // State encoding
  localparam STATE_IDLE        = 3'd0,
             STATE_RESET       = 3'd1,
             STATE_MODULE_RST  = 3'd2,
             STATE_MEM_CLEAR   = 3'd3,
             STATE_WAIT        = 3'd4;

  reg [2:0]  state, state_next;
  reg [7:0]  counter, counter_next;

  reg        system_reset,         system_reset_next;
  reg        module_reset,         module_reset_next;
  reg        memory_clear,         memory_clear_next;
  reg        recovery_in_progress, recovery_in_progress_next;
  reg [3:0]  recovery_stage,       recovery_stage_next;

  // Counter terminal values for each state
  localparam [7:0] CNT_RESET_TERM      = 8'hFF;
  localparam [7:0] CNT_MODULE_RST_TERM = 8'h7F;
  localparam [7:0] CNT_MEM_CLEAR_TERM  = 8'h3F;
  localparam [7:0] CNT_WAIT_TERM       = 8'hFF;

  // AXI4-Lite Write FSM
  localparam WR_IDLE   = 2'd0,
             WR_DATA   = 2'd1,
             WR_RESP   = 2'd2;
  reg [1:0]  wr_state, wr_state_next;
  reg [AXI_ADDR_WIDTH-1:0] wr_addr_reg;

  // AXI4-Lite Read FSM
  localparam RD_IDLE   = 2'd0,
             RD_DATA   = 2'd1;
  reg [1:0]  rd_state, rd_state_next;
  reg [AXI_ADDR_WIDTH-1:0] rd_addr_reg;

  // Combinational next-state logic for recovery sequence
  always @* begin
    state_next               = state;
    counter_next             = counter;
    system_reset_next        = 1'b0;
    module_reset_next        = 1'b0;
    memory_clear_next        = 1'b0;
    recovery_in_progress_next= recovery_in_progress;
    recovery_stage_next      = recovery_stage;

    case (state)
      STATE_IDLE: begin
        if (trigger_recovery) begin
          state_next                = STATE_RESET;
          counter_next              = 8'h00;
          recovery_in_progress_next = 1'b1;
          recovery_stage_next       = 4'h1;
        end
      end

      STATE_RESET: begin
        system_reset_next = 1'b1;
        counter_next      = counter + 8'd1;

        if (counter == CNT_RESET_TERM) begin
          state_next          = STATE_MODULE_RST;
          counter_next        = 8'h00;
          system_reset_next   = 1'b0;
          recovery_stage_next = 4'h2;
        end
      end

      STATE_MODULE_RST: begin
        module_reset_next = 1'b1;
        counter_next      = counter + 8'd1;

        if (counter == CNT_MODULE_RST_TERM) begin
          state_next           = STATE_MEM_CLEAR;
          counter_next         = 8'h00;
          module_reset_next    = 1'b0;
          recovery_stage_next  = 4'h3;
        end
      end

      STATE_MEM_CLEAR: begin
        memory_clear_next = 1'b1;
        counter_next      = counter + 8'd1;

        if (counter == CNT_MEM_CLEAR_TERM) begin
          state_next          = STATE_WAIT;
          counter_next        = 8'h00;
          memory_clear_next   = 1'b0;
          recovery_stage_next = 4'h4;
        end
      end

      STATE_WAIT: begin
        counter_next = counter + 8'd1;

        if (counter == CNT_WAIT_TERM) begin
          state_next                = STATE_IDLE;
          recovery_in_progress_next = 1'b0;
          recovery_stage_next       = 4'h0;
          counter_next              = 8'h00;
        end
      end

      default: begin
        state_next               = STATE_IDLE;
        counter_next             = 8'h00;
        system_reset_next        = 1'b0;
        module_reset_next        = 1'b0;
        memory_clear_next        = 1'b0;
        recovery_in_progress_next= 1'b0;
        recovery_stage_next      = 4'h0;
      end
    endcase
  end

  // AXI4-Lite Write FSM
  always @* begin
    wr_state_next     = wr_state;
    s_axi_awready     = 1'b0;
    s_axi_wready      = 1'b0;
    s_axi_bvalid      = 1'b0;
    s_axi_bresp       = 2'b00;

    case (wr_state)
      WR_IDLE: begin
        if (s_axi_awvalid) begin
          wr_state_next = WR_DATA;
          s_axi_awready = 1'b1;
        end
      end
      WR_DATA: begin
        if (s_axi_wvalid) begin
          wr_state_next = WR_RESP;
          s_axi_wready  = 1'b1;
        end
      end
      WR_RESP: begin
        s_axi_bvalid = 1'b1;
        s_axi_bresp  = 2'b00;
        if (s_axi_bready) begin
          wr_state_next = WR_IDLE;
        end
      end
      default: wr_state_next = WR_IDLE;
    endcase
  end

  // AXI4-Lite Read FSM
  always @* begin
    rd_state_next   = rd_state;
    s_axi_arready   = 1'b0;
    s_axi_rvalid    = 1'b0;
    s_axi_rdata     = {AXI_DATA_WIDTH{1'b0}};
    s_axi_rresp     = 2'b00;

    case (rd_state)
      RD_IDLE: begin
        if (s_axi_arvalid) begin
          rd_state_next = RD_DATA;
          s_axi_arready = 1'b1;
        end
      end
      RD_DATA: begin
        s_axi_rvalid = 1'b1;
        case (rd_addr_reg)
          4'h0: s_axi_rdata = {7'b0, recovery_in_progress}; // status: in progress
          4'h1: s_axi_rdata = {4'b0, recovery_stage};       // status: stage
          4'h2: s_axi_rdata = {7'b0, system_reset};         // status: system_reset
          4'h3: s_axi_rdata = {7'b0, module_reset};         // status: module_reset
          4'h4: s_axi_rdata = {7'b0, memory_clear};         // status: memory_clear
          4'h5: s_axi_rdata = {7'b0, trigger_recovery_reg}; // control: trigger value
          default: s_axi_rdata = {AXI_DATA_WIDTH{1'b0}};
        endcase
        s_axi_rresp = 2'b00;
        if (s_axi_rready) begin
          rd_state_next = RD_IDLE;
        end
      end
      default: rd_state_next = RD_IDLE;
    endcase
  end

  // AXI4-Lite mapped register write
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      trigger_recovery_reg <= 1'b0;
      wr_addr_reg          <= {AXI_ADDR_WIDTH{1'b0}};
    end else begin
      if (wr_state == WR_IDLE && s_axi_awvalid && s_axi_awready) begin
        wr_addr_reg <= s_axi_awaddr;
      end
      if (wr_state == WR_DATA && s_axi_wvalid && s_axi_wready) begin
        if (wr_addr_reg == 4'h5 && s_axi_wstrb[0]) begin
          trigger_recovery_reg <= s_axi_wdata[0];
        end
      end
      // Auto-clear trigger if sequence moves out of IDLE
      if (state != STATE_IDLE)
        trigger_recovery_reg <= 1'b0;
    end
  end

  // AXI4-Lite mapped register read address latch
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_addr_reg <= {AXI_ADDR_WIDTH{1'b0}};
    end else begin
      if (rd_state == RD_IDLE && s_axi_arvalid && s_axi_arready) begin
        rd_addr_reg <= s_axi_araddr;
      end
    end
  end

  // Synchronous sequential logic for recovery sequence
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state                  <= STATE_IDLE;
      counter                <= 8'h00;
      recovery_stage         <= 4'h0;
      recovery_in_progress   <= 1'b0;
      system_reset           <= 1'b0;
      module_reset           <= 1'b0;
      memory_clear           <= 1'b0;
      wr_state               <= WR_IDLE;
      rd_state               <= RD_IDLE;
    end else begin
      state                  <= state_next;
      counter                <= counter_next;
      system_reset           <= system_reset_next;
      module_reset           <= module_reset_next;
      memory_clear           <= memory_clear_next;
      recovery_in_progress   <= recovery_in_progress_next;
      recovery_stage         <= recovery_stage_next;
      wr_state               <= wr_state_next;
      rd_state               <= rd_state_next;
    end
  end

endmodule