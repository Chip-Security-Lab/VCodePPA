//SystemVerilog
module crossbar_arbiter #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  integer i, j;
  
  // Internal combinational signals for grant computation
  reg [N-1:0] src_gnt_comb;
  reg [N-1:0] dst_gnt_comb [N-1:0];
  
  // Computational logic moved before registers
  always @(*) begin
    // Default values
    src_gnt_comb = {N{1'b0}};
    for (i = 0; i < N; i = i + 1) dst_gnt_comb[i] = {N{1'b0}};
    
    // Grant computation logic
    for (i = 0; i < N; i = i + 1) begin
      if (src_req[i]) begin
        for (j = 0; j < N; j = j + 1) begin
          if (dst_sel[i][j] && !dst_gnt_comb[j]) begin
            src_gnt_comb[i] = 1'b1;
            dst_gnt_comb[j] = 1'b1;
          end
        end
      end
    end
  end
  
  // Register stage moved after combinational logic
  always @(posedge clk) begin
    if (rst) begin
      src_gnt <= {N{1'b0}};
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= {N{1'b0}};
    end else begin
      src_gnt <= src_gnt_comb;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= dst_gnt_comb[i];
    end
  end
endmodule