module debug_reset_controller(
  input clk, ext_rst_n,
  input dbg_enable, dbg_halt, dbg_step, dbg_reset,
  output reg cpu_rst_n, periph_rst_n,
  output reg [1:0] debug_state
);
  localparam NORMAL = 2'b00, HALTED = 2'b01, STEPPING = 2'b10, DBG_RESET = 2'b11;
  reg [1:0] state = NORMAL;
  
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      state <= NORMAL;
      cpu_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      debug_state <= NORMAL;
    end else begin
      case (state)
        NORMAL: begin
          if (dbg_enable && dbg_halt)
            state <= HALTED;
          else if (dbg_enable && dbg_reset)
            state <= DBG_RESET;
          cpu_rst_n <= 1'b1;
          periph_rst_n <= 1'b1;
        end
        HALTED: begin
          if (!dbg_enable)
            state <= NORMAL;
          else if (dbg_step)
            state <= STEPPING;
          else if (dbg_reset)
            state <= DBG_RESET;
          cpu_rst_n <= 1'b0;
          periph_rst_n <= 1'b1;
        end
        STEPPING: begin
          state <= HALTED;
          cpu_rst_n <= 1'b1;
          periph_rst_n <= 1'b1;
        end
        DBG_RESET: begin
          state <= HALTED;
          cpu_rst_n <= 1'b0;
          periph_rst_n <= 1'b0;
        end
      endcase
      debug_state <= state;
    end
  end
endmodule