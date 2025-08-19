//SystemVerilog
///////////////////////////////////////////////////////////////////////////
// Module: adaptive_reset_threshold
// Description: Top module for adaptive threshold reset controller with
//              Valid-Ready handshake interface
///////////////////////////////////////////////////////////////////////////
module adaptive_reset_threshold (
  input  wire       clk,
  input  wire       valid_in,     // Input valid signal (was req)
  input  wire [7:0] signal_level,
  input  wire [7:0] base_threshold,
  input  wire [3:0] hysteresis,
  output wire       ready_in,     // Input ready signal (was ack)
  output wire       valid_out,    // Output valid signal
  output wire       reset_trigger,
  input  wire       ready_out     // Output ready signal
);

  // Internal signals
  wire [7:0] current_threshold;
  wire comp_valid_out, comp_ready_in;
  wire thm_valid_out, thm_ready_in;
  
  // Instantiate the comparator module to detect threshold crossings
  threshold_comparator comparator_inst (
    .clk              (clk),
    .valid_in         (valid_in),
    .signal_level     (signal_level),
    .current_threshold(current_threshold),
    .ready_in         (ready_in),
    .valid_out        (comp_valid_out),
    .reset_trigger    (reset_trigger),
    .ready_out        (thm_ready_in)
  );
  
  // Instantiate the threshold manager to handle threshold adjustments
  threshold_manager threshold_inst (
    .clk              (clk),
    .valid_in         (comp_valid_out),
    .reset_trigger    (reset_trigger),
    .base_threshold   (base_threshold),
    .hysteresis       (hysteresis),
    .ready_in         (thm_ready_in),
    .valid_out        (valid_out),
    .current_threshold(current_threshold),
    .ready_out        (ready_out)
  );

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: threshold_comparator
// Description: Compares signal level with threshold and generates reset trigger
//              with Valid-Ready handshake interface
///////////////////////////////////////////////////////////////////////////
module threshold_comparator (
  input  wire       clk,
  input  wire       valid_in,
  input  wire [7:0] signal_level,
  input  wire [7:0] current_threshold,
  output reg        ready_in,
  output reg        valid_out,
  output reg        reset_trigger,
  input  wire       ready_out
);

  reg processing;
  
  // Handshake logic
  always @(posedge clk) begin
    if (!processing && valid_in) begin
      // Accept new data
      processing <= 1'b1;
      ready_in <= 1'b1;
    end else if (processing && valid_out && ready_out) begin
      // Data transfer complete
      processing <= 1'b0;
      ready_in <= 1'b0;
    end else begin
      ready_in <= !processing;
    end
  end

  // Comparison logic with valid-ready control
  always @(posedge clk) begin
    if (processing && !valid_out) begin
      if (signal_level < current_threshold && !reset_trigger) begin
        reset_trigger <= 1'b1;
        valid_out <= 1'b1;
      end else if (signal_level > current_threshold && reset_trigger) begin
        reset_trigger <= 1'b0;
        valid_out <= 1'b1;
      end else begin
        valid_out <= 1'b1; // Always produce valid output after processing
      end
    end else if (valid_out && ready_out) begin
      valid_out <= 1'b0; // Clear valid when handshake completes
    end
  end

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: threshold_manager
// Description: Manages the adaptive threshold value based on trigger state
//              with Valid-Ready handshake interface
///////////////////////////////////////////////////////////////////////////
module threshold_manager (
  input  wire       clk,
  input  wire       valid_in,
  input  wire       reset_trigger,
  input  wire [7:0] base_threshold,
  input  wire [3:0] hysteresis,
  output reg        ready_in,
  output reg        valid_out,
  output reg  [7:0] current_threshold,
  input  wire       ready_out
);

  reg processing;
  reg [7:0] next_threshold;

  // Initialize threshold to base value
  initial begin
    current_threshold = base_threshold;
    processing = 1'b0;
    ready_in = 1'b1;
    valid_out = 1'b0;
  end

  // Handshake and processing logic
  always @(posedge clk) begin
    // Input handshake
    if (!processing && valid_in) begin
      processing <= 1'b1;
      ready_in <= 1'b0;
      
      // Compute next threshold based on trigger
      if (reset_trigger) begin
        next_threshold <= base_threshold + hysteresis;
      end else begin
        next_threshold <= base_threshold;
      end
      
    end else if (processing && valid_out && ready_out) begin
      // Output handshake complete
      processing <= 1'b0;
      ready_in <= 1'b1;
    end
  end
  
  // Output handshake
  always @(posedge clk) begin
    if (processing && !valid_out) begin
      current_threshold <= next_threshold;
      valid_out <= 1'b1;
    end else if (valid_out && ready_out) begin
      valid_out <= 1'b0;
    end
  end

endmodule