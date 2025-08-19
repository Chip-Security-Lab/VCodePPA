//SystemVerilog
module multi_bit_parity(
  input clk,
  input rst_n,
  input req,
  output ack,
  input [15:0] data_word,
  output [1:0] parity_bits
);

  reg ack_reg;
  reg [1:0] parity_bits_reg;
  reg req_prev;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_reg <= 1'b0;
      parity_bits_reg <= 2'b0;
      req_prev <= 1'b0;
    end else begin
      req_prev <= req;
      if (req && !req_prev) begin
        ack_reg <= 1'b1;
        parity_bits_reg[0] <= ^data_word[7:0];
        parity_bits_reg[1] <= ^data_word[15:8];
      end else if (!req) begin
        ack_reg <= 1'b0;
      end
    end
  end

  assign ack = ack_reg;
  assign parity_bits = parity_bits_reg;

endmodule