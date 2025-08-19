module prio_enc_weighted #(parameter N=4)(
  input clk,
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg [1:0] max_idx
);
reg [7:0] max_weight;
integer i; // 改为integer类型
always @(posedge clk) begin
  max_weight = 0;
  max_idx = 0;
  for(i=0; i<N; i=i+1) // 使用标准Verilog循环
    if(req[i] && weight[i] > max_weight) begin
      max_weight = weight[i];
      max_idx = i;
    end
end
endmodule