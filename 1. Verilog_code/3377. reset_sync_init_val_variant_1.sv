//SystemVerilog
//-----------------------------------------------------------------------------
// File Name: reset_sync_system.v
// Module: reset_sync_system - Top level reset synchronization system
// Description: Optimized hierarchical implementation of reset synchronizer with
//              configurable initial value
//-----------------------------------------------------------------------------
module reset_sync_system #(
  parameter INIT_VAL = 1'b0
)(
  input  wire clk,      // System clock
  input  wire rst_n,    // Asynchronous reset (active low)
  output wire rst_sync  // Synchronized reset output
);

  // Intermediate signals using direct connection for better timing
  (* dont_touch = "true" *) wire flop_out;
  
  // First stage flip-flop for reset synchronization
  reset_stage_one #(
    .INIT_VAL(INIT_VAL)
  ) u_stage_one (
    .clk      (clk),
    .rst_n    (rst_n),
    .stage_out(flop_out)
  );
  
  // Second stage flip-flop for reset synchronization
  reset_stage_two #(
    .INIT_VAL(INIT_VAL)
  ) u_stage_two (
    .clk       (clk),
    .rst_n     (rst_n),
    .stage_in  (flop_out),
    .sync_reset(rst_sync)
  );

endmodule

//-----------------------------------------------------------------------------
// Module: reset_stage_one - First stage of reset synchronization
// Description: Captures asynchronous reset and creates first stage output
//-----------------------------------------------------------------------------
module reset_stage_one #(
  parameter INIT_VAL = 1'b0
)(
  input  wire clk,
  input  wire rst_n,
  output reg  stage_out
);

  // Pre-compute the constant value to reduce logic depth
  localparam RESET_VALUE = INIT_VAL;
  localparam NORMAL_VALUE = ~INIT_VAL;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage_out <= RESET_VALUE;
    end else begin
      stage_out <= NORMAL_VALUE;
    end
  end

endmodule

//-----------------------------------------------------------------------------
// Module: reset_stage_two - Second stage of reset synchronization
// Description: Creates metastability-free synchronized reset output
//-----------------------------------------------------------------------------
module reset_stage_two #(
  parameter INIT_VAL = 1'b0
)(
  input  wire clk,
  input  wire rst_n,
  input  wire stage_in,
  output reg  sync_reset
);

  // Pre-compute the constant value
  localparam RESET_VALUE = INIT_VAL;

  // Simplified reset logic with direct signal path
  (* async_reg = "true" *) reg sync_reset_meta;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reset <= RESET_VALUE;
    end else begin
      sync_reset <= stage_in;
    end
  end

endmodule