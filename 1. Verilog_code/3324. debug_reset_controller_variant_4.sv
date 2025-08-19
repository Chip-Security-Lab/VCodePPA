//SystemVerilog
module debug_reset_controller(
  input  wire        clk,
  input  wire        ext_rst_n,
  input  wire        dbg_enable,
  input  wire        dbg_halt,
  input  wire        dbg_step,
  input  wire        dbg_reset,
  output reg         cpu_rst_n,
  output reg         periph_rst_n,
  output reg  [3:0]  debug_state
);

  // FSM state encoding
  localparam STATE_NORMAL    = 4'b0001;
  localparam STATE_HALTED    = 4'b0010;
  localparam STATE_STEPPING  = 4'b0100;
  localparam STATE_DBG_RESET = 4'b1000;

  // Pipeline stage 1: Input synchronization and decoding
  reg dbg_enable_sync, dbg_halt_sync, dbg_step_sync, dbg_reset_sync;
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      dbg_enable_sync <= 1'b0;
      dbg_halt_sync   <= 1'b0;
      dbg_step_sync   <= 1'b0;
      dbg_reset_sync  <= 1'b0;
    end else begin
      dbg_enable_sync <= dbg_enable;
      dbg_halt_sync   <= dbg_halt;
      dbg_step_sync   <= dbg_step;
      dbg_reset_sync  <= dbg_reset;
    end
  end

  // Pipeline stage 2: FSM next state logic with optimized comparisons
  reg  [3:0] fsm_state_reg;
  reg  [3:0] fsm_next_state;
  always @(*) begin : fsm_next_state_logic
    // Priority: reset > step > halt > normal
    case (fsm_state_reg)
      STATE_NORMAL: begin
        if (dbg_enable_sync) begin
          if (dbg_reset_sync)
            fsm_next_state = STATE_DBG_RESET;
          else if (dbg_halt_sync)
            fsm_next_state = STATE_HALTED;
          else
            fsm_next_state = STATE_NORMAL;
        end else begin
          fsm_next_state = STATE_NORMAL;
        end
      end
      STATE_HALTED: begin
        if (!dbg_enable_sync)
          fsm_next_state = STATE_NORMAL;
        else if (dbg_reset_sync)
          fsm_next_state = STATE_DBG_RESET;
        else if (dbg_step_sync)
          fsm_next_state = STATE_STEPPING;
        else
          fsm_next_state = STATE_HALTED;
      end
      STATE_STEPPING: begin
        fsm_next_state = STATE_HALTED;
      end
      STATE_DBG_RESET: begin
        fsm_next_state = STATE_HALTED;
      end
      default: begin
        fsm_next_state = STATE_NORMAL;
      end
    endcase
  end

  // Pipeline stage 2: FSM state register
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n)
      fsm_state_reg <= STATE_NORMAL;
    else
      fsm_state_reg <= fsm_next_state;
  end

  // Pipeline stage 3: Output control logic with optimized state decoding
  reg cpu_rst_n_ctrl, periph_rst_n_ctrl;
  always @(*) begin : output_control_logic
    cpu_rst_n_ctrl    = (fsm_state_reg == STATE_NORMAL) || (fsm_state_reg == STATE_STEPPING);
    periph_rst_n_ctrl = (fsm_state_reg == STATE_NORMAL) || (fsm_state_reg == STATE_HALTED) || (fsm_state_reg == STATE_STEPPING);
  end

  // Pipeline stage 4: Output registers
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      cpu_rst_n     <= 1'b0;
      periph_rst_n  <= 1'b0;
      debug_state   <= STATE_NORMAL;
    end else begin
      cpu_rst_n     <= cpu_rst_n_ctrl;
      periph_rst_n  <= periph_rst_n_ctrl;
      debug_state   <= fsm_state_reg;
    end
  end

endmodule