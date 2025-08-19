//SystemVerilog
// Top-level module
module reset_source_identifier (
  input wire clk,
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output wire [3:0] reset_source
);

  // Internal signals
  wire reset_detected;
  wire [3:0] encoded_reset;

  // Reset detection submodule
  reset_detector u_reset_detector (
    .sys_reset(sys_reset),
    .pwr_reset(pwr_reset),
    .wdt_reset(wdt_reset),
    .sw_reset(sw_reset),
    .reset_detected(reset_detected)
  );

  // Reset priority encoding submodule
  reset_encoder u_reset_encoder (
    .sys_reset(sys_reset),
    .pwr_reset(pwr_reset),
    .wdt_reset(wdt_reset),
    .sw_reset(sw_reset),
    .encoded_reset(encoded_reset)
  );

  // Reset source capture and synchronization
  reset_capture u_reset_capture (
    .clk(clk),
    .reset_detected(reset_detected),
    .encoded_reset(encoded_reset),
    .reset_source(reset_source)
  );

endmodule

// Reset detection module
module reset_detector (
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output wire reset_detected
);

  // Detect if any reset is active
  assign reset_detected = sys_reset | pwr_reset | wdt_reset | sw_reset;

endmodule

// Reset priority encoder module
module reset_encoder (
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output reg [3:0] encoded_reset
);

  // Priority encoding of reset sources
  always @(*) begin
    if (pwr_reset)
      encoded_reset = 4'h1;
    else if (wdt_reset)
      encoded_reset = 4'h2;
    else if (sw_reset)
      encoded_reset = 4'h3;
    else if (sys_reset)
      encoded_reset = 4'h4;
    else
      encoded_reset = 4'h0;
  end

endmodule

// Reset capture and synchronization
module reset_capture (
  input wire clk,
  input wire reset_detected,
  input wire [3:0] encoded_reset,
  output reg [3:0] reset_source
);

  // Capture and register the encoded reset value
  always @(posedge clk) begin
    if (reset_detected)
      reset_source <= encoded_reset;
    else
      reset_source <= 4'h0;
  end

endmodule