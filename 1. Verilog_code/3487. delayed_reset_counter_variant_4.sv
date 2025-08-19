//SystemVerilog
module one_hot_encoder_reset(
  input clk, rst,
  input req,                  // Request signal (replaces valid)
  input [2:0] binary_in,
  output reg [7:0] one_hot_out,
  output reg ack              // Acknowledge signal (replaces ready)
);
  
  reg data_processed;         // Internal state to track processing status
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      one_hot_out <= 8'h00;
      ack <= 1'b0;
      data_processed <= 1'b0;
    end else begin
      if (req && !data_processed) begin
        // Process data when request is active and not yet processed
        one_hot_out <= (8'h01 << binary_in);
        ack <= 1'b1;          // Acknowledge the request
        data_processed <= 1'b1;
      end else if (!req) begin
        // Reset acknowledge when request is deasserted
        ack <= 1'b0;
        data_processed <= 1'b0;
      end
    end
  end
  
endmodule