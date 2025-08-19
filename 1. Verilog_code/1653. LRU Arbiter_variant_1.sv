//SystemVerilog
module lru_arbiter #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output reg [N-1:0] grant,
  output reg busy
);

  reg [N*N-1:0] lru_matrix;
  reg [N-1:0] grant_next;
  reg busy_next;
  reg found_next;
  wire [N-1:0] request_priority;
  wire [N-1:0] carry_chain;
  wire [N-1:0] sum_chain;
  wire [N-1:0] grant_chain;
  integer k;

  // Carry chain adder implementation
  assign carry_chain[0] = 1'b0;
  assign sum_chain[0] = request[0];
  assign grant_chain[0] = request[0] & ~found_next;

  generate
    genvar i;
    for (i = 1; i < N; i = i + 1) begin : carry_chain_gen
      assign carry_chain[i] = request[i-1] & carry_chain[i-1];
      assign sum_chain[i] = request[i] ^ carry_chain[i];
      assign grant_chain[i] = sum_chain[i] & ~found_next;
    end
  endgenerate

  // Combinational logic for grant and busy
  always @(*) begin
    grant_next = 0;
    busy_next = 0;
    found_next = 0;
    
    if (|request) begin
      busy_next = 1;
      for (k = 0; k < N; k = k + 1) begin
        if (!found_next && grant_chain[k]) begin
          grant_next = (1 << k);
          found_next = 1;
        end
      end
    end
  end

  // Sequential logic
  always @(posedge clk) begin
    if (rst) begin
      lru_matrix <= 0;
      grant <= 0;
      busy <= 0;
    end else begin
      grant <= grant_next;
      busy <= busy_next;
    end
  end

endmodule