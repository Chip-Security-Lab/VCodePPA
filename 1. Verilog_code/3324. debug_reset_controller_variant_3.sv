//SystemVerilog
module debug_reset_controller(
  input  clk,
  input  ext_rst_n,
  input  dbg_enable,
  input  dbg_halt,
  input  dbg_step,
  input  dbg_reset,
  output reg cpu_rst_n,
  output reg periph_rst_n,
  output reg [3:0] debug_state
);

  // One-hot encoding
  localparam [3:0] NORMAL    = 4'b0001;
  localparam [3:0] HALTED    = 4'b0010;
  localparam [3:0] STEPPING  = 4'b0100;
  localparam [3:0] DBG_RESET = 4'b1000;

  // State registers
  reg [3:0] state_reg = NORMAL;
  reg [3:0] next_state_comb;

  // Buffered state encodings for high fanout
  reg [3:0] normal_buf_reg;
  reg [3:0] halted_buf_reg;

  // Buffered next_state signal for fanout reduction
  reg [3:0] next_state_buf_stage1;
  reg [3:0] next_state_buf_stage2;

  // Buffered b0, b1 signals for fanout reduction
  reg b0_buf_stage1, b0_buf_stage2;
  reg b1_buf_stage1, b1_buf_stage2;

  // Internal one-hot state signal
  wire is_normal    = (state_reg == normal_buf_reg);
  wire is_halted    = (state_reg == halted_buf_reg);
  wire is_stepping  = (state_reg == STEPPING);
  wire is_dbg_reset = (state_reg == DBG_RESET);

  // Fanout buffer for NORMAL and HALTED encoding
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      normal_buf_reg <= NORMAL;
      halted_buf_reg <= HALTED;
    end else begin
      normal_buf_reg <= NORMAL;
      halted_buf_reg <= HALTED;
    end
  end

  // Combinational next_state logic
  always @(*) begin
    next_state_comb = state_reg;
    case (state_reg)
      NORMAL: begin
        if (dbg_enable && dbg_halt)
          next_state_comb = halted_buf_reg;
        else if (dbg_enable && dbg_reset)
          next_state_comb = DBG_RESET;
        else
          next_state_comb = normal_buf_reg;
      end
      HALTED: begin
        if (!dbg_enable)
          next_state_comb = normal_buf_reg;
        else if (dbg_step)
          next_state_comb = STEPPING;
        else if (dbg_reset)
          next_state_comb = DBG_RESET;
        else
          next_state_comb = halted_buf_reg;
      end
      STEPPING: begin
        next_state_comb = halted_buf_reg;
      end
      DBG_RESET: begin
        next_state_comb = halted_buf_reg;
      end
      default: next_state_comb = normal_buf_reg;
    endcase
  end

  // Multi-stage buffer for next_state to reduce fanout
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      next_state_buf_stage1 <= NORMAL;
      next_state_buf_stage2 <= NORMAL;
    end else begin
      next_state_buf_stage1 <= next_state_comb;
      next_state_buf_stage2 <= next_state_buf_stage1;
    end
  end

  // Multi-stage buffer for b0 (cpu_rst_n) and b1 (periph_rst_n) signals
  // b0: cpu_rst_n, b1: periph_rst_n
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      b0_buf_stage1 <= 1'b0;
      b0_buf_stage2 <= 1'b0;
      b1_buf_stage1 <= 1'b0;
      b1_buf_stage2 <= 1'b0;
    end else begin
      case (next_state_buf_stage2)
        NORMAL: begin
          b0_buf_stage1 <= 1'b1;
          b1_buf_stage1 <= 1'b1;
        end
        HALTED: begin
          b0_buf_stage1 <= 1'b0;
          b1_buf_stage1 <= 1'b1;
        end
        STEPPING: begin
          b0_buf_stage1 <= 1'b1;
          b1_buf_stage1 <= 1'b1;
        end
        DBG_RESET: begin
          b0_buf_stage1 <= 1'b0;
          b1_buf_stage1 <= 1'b0;
        end
        default: begin
          b0_buf_stage1 <= 1'b0;
          b1_buf_stage1 <= 1'b0;
        end
      endcase
      b0_buf_stage2 <= b0_buf_stage1;
      b1_buf_stage2 <= b1_buf_stage1;
    end
  end

  // State, debug_state, and output assignments with buffered signals
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      state_reg    <= normal_buf_reg;
      debug_state  <= normal_buf_reg;
      cpu_rst_n    <= 1'b0;
      periph_rst_n <= 1'b0;
    end else begin
      state_reg    <= next_state_buf_stage2;
      debug_state  <= next_state_buf_stage2;
      cpu_rst_n    <= b0_buf_stage2;
      periph_rst_n <= b1_buf_stage2;
    end
  end

endmodule