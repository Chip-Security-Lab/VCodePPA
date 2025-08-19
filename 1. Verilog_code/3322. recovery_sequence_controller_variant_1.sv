//SystemVerilog
module recovery_sequence_controller(
  input clk,
  input rst_n,
  input trigger_recovery,
  output reg [3:0] recovery_stage,
  output reg recovery_in_progress,
  output reg system_reset,
  output reg module_reset,
  output reg memory_clear
);
  localparam IDLE = 3'd0, RESET = 3'd1, MODULE_RST = 3'd2, MEM_CLEAR = 3'd3, WAIT = 3'd4;
  reg [2:0] curr_state, next_state;
  reg [7:0] counter, next_counter;
  reg [3:0] next_recovery_stage;
  reg next_recovery_in_progress;
  reg next_system_reset, next_module_reset, next_memory_clear;

  // State transition and output logic (flattened if-else)
  always @(*) begin
    // Default assignments
    next_state = curr_state;
    next_counter = counter;
    next_recovery_stage = recovery_stage;
    next_recovery_in_progress = recovery_in_progress;
    next_system_reset = 1'b0;
    next_module_reset = 1'b0;
    next_memory_clear = 1'b0;

    if (curr_state == IDLE && trigger_recovery) begin
      next_state = RESET;
      next_recovery_in_progress = 1'b1;
      next_recovery_stage = 4'h1;
    end else if (curr_state == RESET && counter == 8'hFF) begin
      next_state = MODULE_RST;
      next_counter = 8'h00;
      next_recovery_stage = 4'h2;
    end else if (curr_state == MODULE_RST && counter == 8'h7F) begin
      next_state = MEM_CLEAR;
      next_counter = 8'h00;
      next_recovery_stage = 4'h3;
    end else if (curr_state == MEM_CLEAR && counter == 8'h3F) begin
      next_state = WAIT;
      next_counter = 8'h00;
      next_recovery_stage = 4'h4;
    end else if (curr_state == WAIT && counter == 8'hFF) begin
      next_state = IDLE;
      next_recovery_in_progress = 1'b0;
      next_recovery_stage = 4'h0;
    end

    // Counter increment logic
    if ((curr_state == RESET && counter != 8'hFF) ||
        (curr_state == MODULE_RST && counter != 8'h7F) ||
        (curr_state == MEM_CLEAR && counter != 8'h3F) ||
        (curr_state == WAIT && counter != 8'hFF)) begin
      next_counter = counter + 1;
    end else if (curr_state == RESET && counter == 8'hFF) begin
      next_counter = 8'h00;
    end else if (curr_state == MODULE_RST && counter == 8'h7F) begin
      next_counter = 8'h00;
    end else if (curr_state == MEM_CLEAR && counter == 8'h3F) begin
      next_counter = 8'h00;
    end else if (curr_state == WAIT && counter == 8'hFF) begin
      next_counter = 8'h00;
    end

    // Output control signals
    if (curr_state == RESET && counter != 8'hFF) begin
      next_system_reset = 1'b1;
    end else if (curr_state == RESET && counter == 8'hFF) begin
      next_system_reset = 1'b0;
    end

    if (curr_state == MODULE_RST && counter != 8'h7F) begin
      next_module_reset = 1'b1;
    end else if (curr_state == MODULE_RST && counter == 8'h7F) begin
      next_module_reset = 1'b0;
    end

    if (curr_state == MEM_CLEAR && counter != 8'h3F) begin
      next_memory_clear = 1'b1;
    end else if (curr_state == MEM_CLEAR && counter == 8'h3F) begin
      next_memory_clear = 1'b0;
    end
  end

  // Sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      curr_state <= IDLE;
      counter <= 8'h00;
      recovery_stage <= 4'h0;
      recovery_in_progress <= 1'b0;
      system_reset <= 1'b0;
      module_reset <= 1'b0;
      memory_clear <= 1'b0;
    end else begin
      curr_state <= next_state;
      counter <= next_counter;
      recovery_stage <= next_recovery_stage;
      recovery_in_progress <= next_recovery_in_progress;
      system_reset <= next_system_reset;
      module_reset <= next_module_reset;
      memory_clear <= next_memory_clear;
    end
  end
endmodule