//SystemVerilog
module reset_sequence_gen(
  input  wire        clk,
  input  wire        trigger_reset,
  input  wire        config_mode,
  input  wire [1:0]  sequence_select,
  output reg         core_rst,
  output reg         periph_rst,
  output reg         mem_rst,
  output reg         io_rst,
  output reg         sequence_done
);

  // Stage 1: Trigger and sequence activation
  reg         trigger_reset_stage1;
  reg         seq_active_stage1;
  reg  [2:0]  seq_counter_stage1;
  reg  [1:0]  sequence_select_stage1;
  reg         valid_stage1;

  // Stage 2: Counter increment and active logic
  reg         seq_active_stage2;
  reg  [2:0]  seq_counter_stage2;
  reg  [1:0]  sequence_select_stage2;
  reg         valid_stage2;
  reg         sequence_done_stage2;

  // Stage 3: Reset signal generation logic
  reg         core_rst_stage3;
  reg         periph_rst_stage3;
  reg         mem_rst_stage3;
  reg         io_rst_stage3;
  reg         sequence_done_stage3;
  reg         valid_stage3;

  // Stage 1: Sequence activation and counter logic
  always @(posedge clk) begin
    trigger_reset_stage1      <= trigger_reset;
    sequence_select_stage1    <= sequence_select;
    valid_stage1              <= 1'b1;

    if (trigger_reset && !seq_active_stage1) begin
      seq_active_stage1   <= 1'b1;
      seq_counter_stage1  <= 3'd0;
    end else if (seq_active_stage1) begin
      seq_active_stage1   <= seq_active_stage1;
      seq_counter_stage1  <= seq_counter_stage1 + 3'd1;
    end else begin
      seq_active_stage1   <= 1'b0;
      seq_counter_stage1  <= seq_counter_stage1;
    end
  end

  // Stage 2: Counter update and sequence done logic
  always @(posedge clk) begin
    seq_active_stage2        <= seq_active_stage1;
    seq_counter_stage2       <= seq_counter_stage1;
    sequence_select_stage2   <= sequence_select_stage1;
    valid_stage2             <= valid_stage1;

    if (seq_active_stage1) begin
      if (seq_counter_stage1 == 3'd7) begin
        sequence_done_stage2 <= 1'b1;
        seq_active_stage2    <= 1'b0;
      end else begin
        sequence_done_stage2 <= 1'b0;
      end
    end else begin
      sequence_done_stage2   <= 1'b0;
    end
  end

  // Stage 3: Reset signal generation logic
  always @(posedge clk) begin
    sequence_done_stage3 <= sequence_done_stage2;
    valid_stage3         <= valid_stage2;

    case (sequence_select_stage2)
      2'b00: begin
        if (seq_active_stage2) begin
          if (seq_counter_stage2 < 3'd2) begin
            core_rst_stage3   <= 1'b1;
            periph_rst_stage3 <= 1'b1;
            mem_rst_stage3    <= 1'b1;
            io_rst_stage3     <= 1'b1;
          end else if (seq_counter_stage2 < 3'd4) begin
            core_rst_stage3   <= 1'b0;
            periph_rst_stage3 <= 1'b1;
            mem_rst_stage3    <= 1'b1;
            io_rst_stage3     <= 1'b1;
          end else if (seq_counter_stage2 < 3'd6) begin
            core_rst_stage3   <= 1'b0;
            periph_rst_stage3 <= 1'b0;
            mem_rst_stage3    <= 1'b1;
            io_rst_stage3     <= 1'b1;
          end else begin
            core_rst_stage3   <= 1'b0;
            periph_rst_stage3 <= 1'b0;
            mem_rst_stage3    <= 1'b0;
            io_rst_stage3     <= 1'b0;
          end
        end else begin
          core_rst_stage3   <= 1'b0;
          periph_rst_stage3 <= 1'b0;
          mem_rst_stage3    <= 1'b0;
          io_rst_stage3     <= 1'b0;
        end
      end

      2'b01: begin
        if (seq_active_stage2) begin
          if (seq_counter_stage2 < 3'd3) begin
            core_rst_stage3   <= 1'b1;
            periph_rst_stage3 <= 1'b1;
            mem_rst_stage3    <= 1'b1;
            io_rst_stage3     <= 1'b1;
          end else if (seq_counter_stage2 < 3'd5) begin
            core_rst_stage3   <= 1'b0;
            periph_rst_stage3 <= 1'b1;
            mem_rst_stage3    <= 1'b0;
            io_rst_stage3     <= 1'b1;
          end else begin
            core_rst_stage3   <= 1'b0;
            periph_rst_stage3 <= 1'b0;
            mem_rst_stage3    <= 1'b0;
            io_rst_stage3     <= 1'b0;
          end
        end else begin
          core_rst_stage3   <= 1'b0;
          periph_rst_stage3 <= 1'b0;
          mem_rst_stage3    <= 1'b0;
          io_rst_stage3     <= 1'b0;
        end
      end

      default: begin
        if (seq_active_stage2) begin
          core_rst_stage3   <= 1'b1;
          periph_rst_stage3 <= 1'b1;
          mem_rst_stage3    <= 1'b1;
          io_rst_stage3     <= 1'b1;
        end else begin
          core_rst_stage3   <= 1'b0;
          periph_rst_stage3 <= 1'b0;
          mem_rst_stage3    <= 1'b0;
          io_rst_stage3     <= 1'b0;
        end
      end
    endcase
  end

  // Output stage: Register outputs for timing closure and pipeline consistency
  always @(posedge clk) begin
    core_rst      <= core_rst_stage3;
    periph_rst    <= periph_rst_stage3;
    mem_rst       <= mem_rst_stage3;
    io_rst        <= io_rst_stage3;
    sequence_done <= sequence_done_stage3;
  end

endmodule