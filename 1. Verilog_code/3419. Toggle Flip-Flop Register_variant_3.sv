//SystemVerilog
module RD9 (
  input  logic clk,       // System clock
  input  logic aresetn,   // Active-low asynchronous reset
  input  logic toggle_en, // Toggle enable signal
  output logic out_signal // Output signal
);

  // Pipeline stage 1: Input registration
  logic toggle_en_stage1;
  
  // Pipeline stage 2: Toggle logic
  logic toggle_state;
  
  // Pipeline stage 3: Output formation
  logic out_signal_next;
  
  // Data path stage 1: Register input control signal
  always_ff @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      toggle_en_stage1 <= 1'b0;
    end else begin
      toggle_en_stage1 <= toggle_en;
    end
  end
  
  // Data path stage 2: Core toggle state machine
  always_ff @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      toggle_state <= 1'b0;
    end else if (toggle_en_stage1) begin
      toggle_state <= ~toggle_state;
    end
  end
  
  // Data path stage 3: Prepare output value
  always_comb begin
    out_signal_next = toggle_state;
  end
  
  // Final output registration
  always_ff @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
      out_signal <= 1'b0;
    end else begin
      out_signal <= out_signal_next;
    end
  end
  
endmodule