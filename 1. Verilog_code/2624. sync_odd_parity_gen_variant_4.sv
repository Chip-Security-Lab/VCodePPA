//SystemVerilog
module sync_odd_parity_gen(
  input clock, resetn,
  input [7:0] din,
  input req_in,
  output reg ack_in,
  output reg p_out,
  output reg req_out
);
  // Stage 1 signals
  reg [3:0] din_high_stage1, din_low_stage1;
  reg req_stage1;
  
  // Stage 2 signals
  reg parity_high_stage2, parity_low_stage2;
  reg req_stage2;
  
  // Stage 1: Split the input and calculate partial parities
  always @(posedge clock) begin
    if (!resetn) begin
      din_high_stage1 <= 4'b0;
      din_low_stage1 <= 4'b0;
      req_stage1 <= 1'b0;
      ack_in <= 1'b0;
    end
    else begin
      if (req_in && !ack_in) begin
        din_high_stage1 <= din[7:4];
        din_low_stage1 <= din[3:0];
        req_stage1 <= 1'b1;
        ack_in <= 1'b1;
      end
      else if (!req_in) begin
        ack_in <= 1'b0;
      end
    end
  end
  
  // Stage 2: Calculate parities of each half
  always @(posedge clock) begin
    if (!resetn) begin
      parity_high_stage2 <= 1'b0;
      parity_low_stage2 <= 1'b0;
      req_stage2 <= 1'b0;
    end
    else begin
      if (req_stage1) begin
        parity_high_stage2 <= ^din_high_stage1;
        parity_low_stage2 <= ^din_low_stage1;
        req_stage2 <= 1'b1;
      end
    end
  end
  
  // Stage 3: Combine parities and generate final odd parity
  always @(posedge clock) begin
    if (!resetn) begin
      p_out <= 1'b0;
      req_out <= 1'b0;
    end
    else begin
      if (req_stage2) begin
        p_out <= ~(parity_high_stage2 ^ parity_low_stage2);
        req_out <= 1'b1;
      end
    end
  end
endmodule