module matrix_arbiter #(parameter CLIENTS=3) (
  input wire clk,
  input wire [CLIENTS-1:0] req_i,
  output reg [CLIENTS-1:0] gnt_o
);
  reg [CLIENTS-1:0] prio [CLIENTS-1:0];
  integer i, j;
  
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) prio[i] = {CLIENTS{1'b0}};
    for (i = 0; i < CLIENTS; i = i + 1)
      for (j = 0; j < CLIENTS; j = j + 1)
        if (i > j) prio[i][j] = 1'b1;
    
    gnt_o = {CLIENTS{1'b0}};
    for (i = 0; i < CLIENTS; i = i + 1)
      gnt_o[i] = req_i[i] & ~|(req_i & prio[i]);
  end
endmodule