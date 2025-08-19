//SystemVerilog
module reset_chain_monitor (
  input wire clk,
  input wire [3:0] reset_chain,
  input wire rst_n,
  input wire req,      // Request signal (replaces valid)
  output reg ack,      // Acknowledge signal (replaces ready)
  output reg reset_chain_error
);

  // Internal pipeline registers
  reg [3:0] reset_chain_stage1;
  reg reset_chain_invalid_pattern;
  reg req_r;           // Registered request signal
  reg processing;      // Processing state indicator
  
  // First pipeline stage: capture and synchronize input data
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_chain_stage1 <= 4'b0000;
      req_r <= 1'b0;
      processing <= 1'b0;
    end else begin
      if (req && !processing && !req_r) begin
        reset_chain_stage1 <= reset_chain;
        req_r <= 1'b1;
        processing <= 1'b1;
      end else if (ack) begin
        req_r <= 1'b0;
        processing <= 1'b0;
      end
    end
  end
  
  // Second pipeline stage: pattern detection logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_chain_invalid_pattern <= 1'b0;
    end else if (processing && req_r) begin
      reset_chain_invalid_pattern <= (reset_chain_stage1 != 4'b0000) && 
                                    (reset_chain_stage1 != 4'b1111);
    end
  end
  
  // Third pipeline stage: generate final error signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_chain_error <= 1'b0;
      ack <= 1'b0;
    end else begin
      if (processing && req_r) begin
        reset_chain_error <= reset_chain_invalid_pattern ? 1'b1 : reset_chain_error;
        ack <= 1'b1;  // Acknowledge when processing is complete
      end else begin
        ack <= 1'b0;  // Clear acknowledge signal
      end
    end
  end

endmodule