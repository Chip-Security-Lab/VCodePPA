//SystemVerilog
module brownout_detector #(
  parameter LOW_THRESHOLD = 8'd85,
  parameter HIGH_THRESHOLD = 8'd95
)(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        enable,
  input  wire [7:0]  supply_voltage,
  output reg         brownout_reset
);

  // Stage 1: Combine input latching, threshold compare and brownout state update
  reg        brownout_state_stage1;
  reg        valid_stage1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      brownout_state_stage1 <= 1'b0;
      valid_stage1          <= 1'b0;
    end else begin
      valid_stage1 <= 1'b1;
      if (!enable) begin
        brownout_state_stage1 <= 1'b0;
      end else if (supply_voltage < LOW_THRESHOLD) begin
        brownout_state_stage1 <= 1'b1;
      end else if (supply_voltage > HIGH_THRESHOLD) begin
        brownout_state_stage1 <= 1'b0;
      end else begin
        brownout_state_stage1 <= brownout_state_stage1;
      end
    end
  end

  // Stage 2: Output register
  reg brownout_reset_stage2;
  reg valid_stage2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      brownout_reset_stage2 <= 1'b0;
      valid_stage2          <= 1'b0;
    end else begin
      brownout_reset_stage2 <= brownout_state_stage1;
      valid_stage2          <= valid_stage1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      brownout_reset <= 1'b0;
    else if (valid_stage2)
      brownout_reset <= brownout_reset_stage2;
  end

endmodule