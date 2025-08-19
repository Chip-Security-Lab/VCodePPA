//SystemVerilog
module parity_gen_with_req_ack(
  input clk,
  input req,
  input [15:0] data_word,
  output reg parity_result,
  output reg ack
);
  reg data_processed;
  
  always @(posedge clk) begin
    if (req && !data_processed) begin
      parity_result <= ^data_word;
      data_processed <= 1'b1;
      ack <= 1'b1;
    end else if (!req) begin
      data_processed <= 1'b0;
      ack <= 1'b0;
    end
  end
endmodule