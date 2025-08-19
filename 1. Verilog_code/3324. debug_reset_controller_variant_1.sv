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
  output reg [1:0] debug_state
);

  localparam NORMAL    = 2'b00,
             HALTED    = 2'b01,
             STEPPING  = 2'b10,
             DBG_RESET = 2'b11;

  reg [1:0] state_reg = NORMAL;
  reg [1:0] state_next;

  // First-stage output pipelines (buffered for high fanout)
  reg cpu_rst_n_buf1, cpu_rst_n_buf2;
  reg periph_rst_n_buf1, periph_rst_n_buf2;
  reg [1:0] debug_state_buf1, debug_state_buf2;

  // State encoding buffers for high fanout constants
  reg [1:0] normal_buf1, normal_buf2;
  reg [1:0] halted_buf1, halted_buf2;

  // Combinational next state and output logic, using local buffers
  always @* begin
    state_next = state_reg;

    cpu_rst_n_buf1    = cpu_rst_n;
    periph_rst_n_buf1 = periph_rst_n;
    debug_state_buf1  = debug_state;

    case (state_reg)
      NORMAL: begin
        if (dbg_enable && dbg_halt)
          state_next = halted_buf2;
        else if (dbg_enable && dbg_reset)
          state_next = DBG_RESET;
        cpu_rst_n_buf1    = 1'b1;
        periph_rst_n_buf1 = 1'b1;
      end
      HALTED: begin
        if (!dbg_enable)
          state_next = normal_buf2;
        else if (dbg_step)
          state_next = STEPPING;
        else if (dbg_reset)
          state_next = DBG_RESET;
        cpu_rst_n_buf1    = 1'b0;
        periph_rst_n_buf1 = 1'b1;
      end
      STEPPING: begin
        state_next = halted_buf2;
        cpu_rst_n_buf1    = 1'b1;
        periph_rst_n_buf1 = 1'b1;
      end
      DBG_RESET: begin
        state_next = halted_buf2;
        cpu_rst_n_buf1    = 1'b0;
        periph_rst_n_buf1 = 1'b0;
      end
      default: begin
        state_next = normal_buf2;
        cpu_rst_n_buf1    = 1'b0;
        periph_rst_n_buf1 = 1'b0;
      end
    endcase
    debug_state_buf1 = state_next;
  end

  // Buffering high fanout state constants (two stage)
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      normal_buf1 <= NORMAL;
      halted_buf1 <= HALTED;
    end else begin
      normal_buf1 <= NORMAL;
      halted_buf1 <= HALTED;
    end
  end

  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      normal_buf2 <= NORMAL;
      halted_buf2 <= HALTED;
    end else begin
      normal_buf2 <= normal_buf1;
      halted_buf2 <= halted_buf1;
    end
  end

  // State register
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      state_reg <= normal_buf2;
    end else begin
      state_reg <= state_next;
    end
  end

  // Stage 1: Buffer outputs for fanout reduction
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      cpu_rst_n_buf2    <= 1'b0;
      periph_rst_n_buf2 <= 1'b0;
      debug_state_buf2  <= normal_buf2;
    end else begin
      cpu_rst_n_buf2    <= cpu_rst_n_buf1;
      periph_rst_n_buf2 <= periph_rst_n_buf1;
      debug_state_buf2  <= debug_state_buf1;
    end
  end

  // Stage 2: Final output registers (fanout balanced)
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      cpu_rst_n     <= 1'b0;
      periph_rst_n  <= 1'b0;
      debug_state   <= normal_buf2;
    end else begin
      cpu_rst_n     <= cpu_rst_n_buf2;
      periph_rst_n  <= periph_rst_n_buf2;
      debug_state   <= debug_state_buf2;
    end
  end

endmodule