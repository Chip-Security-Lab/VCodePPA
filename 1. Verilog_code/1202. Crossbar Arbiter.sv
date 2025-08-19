module crossbar_arbiter #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  integer i, j;
  
  always @(posedge clk) begin
    if (rst) begin
      src_gnt <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= 0;
    end else begin
      src_gnt <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= 0;
      
      for (i = 0; i < N; i = i + 1) begin
        if (src_req[i]) begin
          for (j = 0; j < N; j = j + 1) begin
            if (dst_sel[i][j] && !dst_gnt[j]) begin
              src_gnt[i] <= 1'b1;
              dst_gnt[j] <= 1'b1;
            end
          end
        end
      end
    end
  end
endmodule